from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
import logging
import urllib.request
import json
import pdb

logger = logging.getLogger(__name__)
tz = ZoneInfo("Europe/Stockholm")

class Mission:
    def __init__(self, match):
        self.teams = Mission.get_teamnames(match["competitors"])
        try:
            self.start = datetime.strptime(match["startTime"] , "%Y-%m-%d %H:%M:%S")
        except:
            pdb.set_trace()
        self.start.replace(tzinfo=tz)
        self.end = self.start+timedelta(hours=2)


    def __str__(self):
        return f"<Mission,{self.teams}, {self.start}, {self.end}>"

    def __repr__(self):
        return str(self)

    @staticmethod
    def get_teamnames(competitors):
        return [x["name"] for x in competitors]

    @staticmethod
    def from_korpen_to_missions(matches):
        missions = [Mission(match) for match in matches if "Badminton Gang" in Mission.get_teamnames(match["competitors"]) and match["startTime"]]
        return missions


def get_missions_from_korpen():
    """Returns a list of missions, missions have the required info for a calendar event"""
    url='https://korpengoteborg.zoezi.se/api/teamsport/division/matches/get?id=602'
    contents = urllib.request.urlopen(url).read()
    matches = json.loads(contents)
    missions = Mission.from_korpen_to_missions(matches)
    return missions
