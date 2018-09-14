(import sys
        json
        trio
        asks
        click
        [progress.bar [Bar]]
        [datetime [date datetime timedelta]])

(require [hy.contrib.walk [*]])

(.init asks "trio")

;; (import [http.client :as http-client])
;; (setv http-client.HTTPConnection.debuglevel 1)

(defclass MyBar [Bar]
  [suffix "%(index)d/%(max)d [%(total)d events]"
   total 0]

  (defn next [self &optional [total-incr 1] &rest rest &kwargs kwargs]
    (+= self.total total-incr)
    (.next (super) #* rest #** kwargs)))

(defn/a get-cosign-cookie [s]
  (await (.get s "https://weblogin.lancs.ac.uk/login/?cosign-https-lancaster.ombiel.co.uk&https://lancaster.ombiel.co.uk/campusm/sso/required/login/411")))

(defn/a do-login [s user pass]
  (await (get-cosign-cookie s))
  (let [data
        {"required" ""
         "ref" "https://lancaster.ombiel.co.uk/campusm/sso/required/login/411"
         "service" "cosign-https-lancaster.ombiel.co.uk"
         "login" user
         "password" pass
         "otp" ""
         "doLogin" "Login"}
        resp (await (.post s "https://weblogin.lancs.ac.uk/login/"
                           :data data))]
       resp))

(defn make-session []
  (let [session (.Session
                  asks
                  :connections 10
                  :persist-cookies True)]
    (.headers.update
      session
      {"Connection" "keep-alive"
       "Cache-Control" "max-age=0"
       "Origin" "https://weblogin.lancs.ac.uk"
       "Upgrade-Insecure-Requests" "1"
       "DNT" "1"
       "Content-Type" "application/x-www-form-urlencoded"
       "User-Agent" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.92 Safari/537.36"
       "Accept" "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"
       "Referer" "https://weblogin.lancs.ac.uk/login/?cosign-https-lancaster.ombiel.co.uk&https://lancaster.ombiel.co.uk/campusm/sso/required/login/411"
       "Accept-Encoding" "gzip, deflate, br"
       "Accept-Language" "en-GB,en-US;q=0.9,en;q=0.8"})
    session))

(defn/a get-event [s date]
  (let [tt (.timetuple date)
        year (. tt tm_year)
        day  (. tt tm_yday)
        url (.format "https://lancaster.ombiel.co.uk/campusm/sso/calendar/sso_course_timetable/{}{}" year day)
        resp (await (.get s url))
        json (.json resp)]
       (get json "events")))

(defn datecode-gen [starting-datetime num-weeks]
  (setv delta (timedelta :weeks 1))
  (for [i (range num-weeks)]
    (yield (+ starting-datetime (* delta i)))))

(defn/a get-events [s starting-datetime num-weeks]
  (let [bar (MyBar "Getting events" :max num-weeks)
        d-iter (datecode-gen starting-datetime num-weeks)
        res (list)]

       (with/a [n (trio.open-nursery)]
         (for [date d-iter]
           (.start-soon n (fn/a []
                            (let [evts (await (get-event s date))]
                                 (.append res evts)
                                 (.next bar (len evts)))))))

       (.finish bar)

       (-> res
           (chain.from-iterable)
           (list))))

(defn/a get-events-from-now [s num-weeks]
  (let [now (date.today)]
       (await (get-events s now num-weeks))))

(defn generate-org-entry [event]
  (setv time-format "%Y-%m-%dT%H:%M:%S.%f%z"
        known-fields ["eventRef" "desc1" "desc3" "calDate" "start" "end" "duration" "durationUnit"
                      "teacherName" "teacherEmail" "locCode" "locAdd1" "locAdd2" "id"]
        unknown-fields (lfor
                         [k v] (event.items)
                         :if (not-in k known-fields)
                         (.format "{}: {}" k v)))

  (let [start (datetime.strptime (get event "start") time-format)
        end   (datetime.strptime (get event "end")   time-format)
        start-s (.strftime start "%Y-%m-%d %a %H:%S")
        end-s   (.strftime end "%H:%S")
        org-time (.format "<{}-{}>" start-s end-s)]
       (.format (.join "\n" ["* {type}: {module}"
                             "  :PROPERTIES:"
                             "  :LOCATION: {room}, {location}, {code}"
                             "  :END:"
                             ""
                             "  {org_time}"
                             ""
                             "Length: {duration} {duration_unit}"
                             "Teachers: {teachers}"
                             "Emails?: {emails}"
                             "Type: {type}"
                             "Module: {module}"
                             "Reference: {reference}"
                             "{extra}"])
                :type          (get event "desc3")
                :module        (get event "desc1")
                :room          (get event "locAdd1")
                :location      (get event "locAdd2")
                :code          (get event "locCode")
                :duration      (get event "duration")
                :duration-unit (get event "durationUnit")
                :teachers      (get event "teacherName")
                :emails        (get event "teacherEmail")
                :reference     (get event "eventRef")
                :org-time org-time
                :extra (.join "\n" unknown-fields))))

(defn/a a-main [user password num-weeks]
  (let [s (make-session)]
       (await (do-login s user password))
       (await (get-events-from-now s num-weeks))))

#@((click.command)
   (click.argument "user")
   (click.argument "password")
   (click.option "--weeks" "-w" :default 4 :help "Number of weeks to fetch")
   (click.option "--org" "-o" :is-flag True)
   (defn hy-main [user password weeks org]
     (let [evts (trio.run a-main user password weeks)]
          (print
            (cond
              [org (.join "\n" (map generate-org-entry evts))]
              [True (json.dumps evts)])))))

(defmain [&rest _]
  (hy-main))
