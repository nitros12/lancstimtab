# Lancaster University Timetable Dumper
![PyPI](https://img.shields.io/pypi/v/lancstimtab.svg)
![PyPI - Python Version](https://img.shields.io/pypi/pyversions/lancstimtab.svg)

Useful for extracting your timetable into json, ics, or org-mode format.

## Usage

```
Usage: lancstimtab [OPTIONS] USER PASSWORD

Options:
  -w, --weeks INTEGER          Number of weeks to fetch
  -f, --format [json|org|ics]
  --help                       Show this message and exit.
```

`lancstimtab <username> <password> --format ics --weeks 6`

```ics
Getting events |################################| 6/6 [37 events]
BEGIN:VCALENDAR
PRODID:ics.py - http://git.io/lLljaA
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:20180917T000155Z
DTSTART:20181018T100000Z
DTEND:20181018T110000Z
SUMMARY:SCC.120/W01/04
DESCRIPTION:Teachers: Chopra\, AK / Mariani\, JA / Porter\, BF / Sas\, C\nEmails?: \nType: Workshop\nModule: SCC.120/W01/04\nReference: 25518-000118-6198\n
LOCATION:WEL - Welcome Centre LT3 A40\, Welcome Centre\, 10866
TRANSP:OPAQUE
UID:25518-000118-6198
CATEGORIES:Workshop
END:VEVENT
END:VCALENDAR
```
