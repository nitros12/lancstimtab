from setuptools import setup, find_packages

from codecs import open
from os import path

with open("readme.md") as f:
    long_desc = f.read()

with open("requirements.txt") as f:
    requirements = f.read().splitlines()

setup(
    name="lancstimtab",
    version="0.2.0",
    license="GPLv3",
    description="Lancaster University Timetable Dumper",
    author="Ben Simms",
    url='https://github.com/nitros12/lancstimtab',
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
    },
    classifiers=[
        "Programming Language :: Python :: 3.5",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Topic :: Utilities",
    ]
)
