(import sys
        ics
        json
        trio
        asks
        arrow
        click
        [progress.bar [Bar]])

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

(defn dedup [i &optional [by (fn [i] i)]]
  (setv seen (set)
        adder seen.add)
  (lfor
    x i
    :setv key (by x)
    :if (not-in key seen)
    :do (adder key)
    x))

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
  (.Session
    asks
    :connections 10
    :persist-cookies True))

(defn/a get-event [s date]
  (let [tt (.timetuple date)
        year (. tt tm_year)
        day  (. tt tm_yday)
        url (.format "https://lancaster.ombiel.co.uk/campusm/sso/calendar/sso_course_timetable/{}{}" year day)
        resp (await (.get s url))
        json (.json resp)]
       (get json "events")))

(defn datecode-gen [starting-date num-weeks]
  (for [i (range num-weeks)]
    (yield (.shift starting-date :weeks i))))

(defn week-start [date]
  "get the date of the week starting the given date."
  (.shift date
          :days (- (.weekday date))))

(defn/a get-events [s starting-date num-weeks]
  (let [bar (MyBar "Getting events" :max num-weeks)
        d-iter (datecode-gen (week-start starting-date) num-weeks)
        res (list)]

       (with/a [n (trio.open-nursery)]
         (for [date d-iter]
           (.start-soon n
                        (fn/a [date]
                          (let [evts (await (get-event s date))]
                               (.extend res evts)
                               (.next bar (len evts))))
                        date)))

       (.finish bar)

       (-> res
           (dedup (fn [x] (get x "eventRef")))
           (list))))

(defn/a get-events-from-now [s num-weeks]
  (let [now (arrow.utcnow)]
       (await (get-events s now num-weeks))))

(defn get-times [evt]
  "Get the starting and ending datetimes of an event as a tuple of (start, end)."
  (let [start (arrow.get (get evt "start"))
        end   (arrow.get (get evt "end"))]
       (, start end)))

(defn get-unknown-fields [evt]
  "Get any fields we don't know from the event."
  (setv known-fields ["eventRef" "desc1" "desc3" "calDate" "start" "end" "duration" "durationUnit"
                      "teacherName" "teacherEmail" "locCode" "locAdd1" "locAdd2" "id"])
  (lfor
    [k v] (evt.items)
    :if (not-in k known-fields)
    (.format "{}: {}" k v)))

(defn generate-org-entry [evt]
  "Generate a single org entry for an event."
  (setv [start end] (get-times evt))
  (let [start-s (.format start "YYYY-MM-DD ddd HH:mm")
        end-s   (.format end "HH:mm")
        org-time (.format "<{}-{}>" start-s end-s)
        unknown-fields (get-unknown-fields evt)]
       (.format (.join "\n" ["* {module}"
                             "  :PROPERTIES:"
                             "  :CATEGORY: {type}"
                             "  :LOCATION: {room}, {location}, {code}"
                             "  :END:"
                             ""
                             "  {org_time}"
                             ""
                             "Teachers: {teachers}"
                             "Emails?: {emails}"
                             "Type: {type}"
                             "Module: {module}"
                             "Reference: {reference}"
                             "{extra}"])
                :type          (get evt "desc3")
                :module        (get evt "desc1")
                :room          (get evt "locAdd1")
                :location      (get evt "locAdd2")
                :code          (get evt "locCode")
                :duration      (get evt "duration")
                :duration-unit (get evt "durationUnit")
                :teachers      (get evt "teacherName")
                :emails        (get evt "teacherEmail")
                :reference     (get evt "eventRef")
                :org-time org-time
                :extra (.join "\n" unknown-fields))))

(defn generate-ics-entry [evt]
  "Generate a single ics entry for an event."
  (setv [start end] (get-times evt))
  (let [unknown-fields (get-unknown-fields evt)
        module    (get evt "desc1")
        room      (get evt "locAdd1")
        location  (get evt "locAdd2")
        code      (get evt "locCode")
        type      (get evt "desc3")
        reference (get evt "eventRef")
        location-str (.format "{}, {}, {}" room location code)
        desc-str (.format
                   (.join "\n" ["Teachers: {teachers}"
                                "Emails?: {emails}"
                                "Type: {type}"
                                "Module: {module}"
                                "Reference: {reference}"
                                "{extra}"])
                   :teachers  (get evt "teacherName")
                   :emails    (get evt "teacherEmail")
                   :type      type
                   :module    module
                   :reference reference
                   :extra (.join "\n" unknown-fields))]
       (ics.Event
         :name        module
         :begin       start
         :end         end
         :uid         reference
         :location    location-str
         :description desc-str
         :categories  (set [type]))))

(defn generate-ics-calendar [events]
  "Generate a ics format calendar from a list of events."
  (ics.Calendar :events (lfor e events (generate-ics-entry e))))


(defn/a a-main [user password num-weeks]
  (let [s (make-session)]
       (await (do-login s user password))
       (await (get-events-from-now s num-weeks))))

#@((click.command)
   (click.argument "user")
   (click.argument "password")
   (click.option "--weeks" "-w" :default 4 :help "Number of weeks to fetch")
   (click.option "--format" "-f" :default "json" :type (click.Choice ["json" "org" "ics"]))
   (defn hy-main [user password weeks format]
     (let [evts (trio.run a-main user password weeks)]
          (print
            (cond
              [(= format "json") (json.dumps evts)]
              [(= format "ics") (generate-ics-calendar evts)]
              [(= format "org") (.join "\n" (map generate-org-entry evts))])))))

(defmain [&rest _]
  (hy-main))
