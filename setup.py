from setuptools import setup, find_packages

from codecs import open
from os import path

here = path.abspath(path.dirname(__file__))

with open(path.join(here, "readme.md")) as f:
    long_desc = f.read()

with open("requirements.txt") as f:
    requirements = f.read().splitlines()

setup(
    name="lancstimtab",
    version="0.1.0",
    description="Lancaster University Timetable Dumper",
    author="Ben Simms",
    packages=find_packages(),
    install_requires=requirements,
    include_package_data=True,
    package_data={
        "lancstimtab": ["*.hy", "__pycache__/*"]
    },
    entry_points={
        "console_scripts": [
            "lancstimtab=lancstimtab.run:main"
        ]
    }
)
