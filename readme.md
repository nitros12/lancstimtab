# Lancaster University Timetable Dumper
![PyPI](https://img.shields.io/pypi/v/lancstimtab.svg)
![PyPI - Python Version](https://img.shields.io/pypi/pyversions/lancstimtab.svg)

Useful for extracting your timetable into json, or org-mode format.

## Example

`lancstimtab <username> <password> --weeks 3 --org`

```org
* Practical: SCC.110/P01/03
  :PROPERTIES:
  :LOCATION: SAT - Science & Technology B070, Science and Technology, 25980
  :END:

  <2018-11-21 Wed 15:00-17:00>

Length: 120 Minutes
Teachers: Chandler, AK / Davies, NAJ / Finney, J / Friday, AJ / Vidler, JE
Emails?:
Type: Practical
Module: SCC.110/P01/03
Reference: 25510-000118-6203

* Workshop: SCC.120/W01/04
  :PROPERTIES:
  :LOCATION: WEL - Welcome Centre LT3 A40, Welcome Centre, 10866
  :END:

  <2018-11-22 Thu 11:00-12:00>

Length: 60 Minutes
Teachers: Chopra, AK / Mariani, JA / Porter, BF / Sas, C
Emails?:
Type: Workshop
Module: SCC.120/W01/04
Reference: 25518-000118-6203
```
