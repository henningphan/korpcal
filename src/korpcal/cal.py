from icalendar import Calendar, Event
from datetime import datetime
from zoneinfo import ZoneInfo

tz = ZoneInfo("Europe/Stockholm")

def static_cal():
    """Used for testing"""
    calendar = Calendar()

    event = Event()
    event.add("name", "name")
    event.add("description", "description")
    event.add("summary", "summary")
    event.add("dtstart", datetime(2025, 11,11, tzinfo=tz))
    event.add("dtend", datetime(2025, 11,11, tzinfo=tz))
    calendar.add_component(event)
    event = Event()
    event.add("name", "name2")
    event.add("summary", "summary2")
    event.add("description", "description2")
    event.add("dtstart", datetime(2025, 12,12, tzinfo=tz))
    event.add("dtend", datetime(2025, 12,12, tzinfo=tz))
    calendar.add_component(event)
    event = Event()
    event.add("name", "name3")
    event.add("summary", "summary3")
    event.add("description", "description3")
    event.add("dtstart", datetime(2025, 12,13, tzinfo=tz))
    event.add("dtend", datetime(2025, 12,13, tzinfo=tz))
    calendar.add_component(event)
    return calendar

def from_missions(missions):
    calendar = Calendar()
    for m in missions:
        event = Event()
        event.add("name", "korpen")
        event.add("uid", str(m.start))
        event.add("summary", f"{', '.join(m.teams)}")
        event.add("description",f"{', '.join(m.teams)}")
        event.add("dtstart", m.start)
        event.add("dtend", m.end)
        calendar.add_component(event)
    return calendar

def broken():
    """makes a calendar with event today that says broken to inform user that something has failed"""
    calendar = Calendar()
    event = Event()
    event.add("name", "korpen")
    event.add("uid", "1")
    event.add("description", "korpen broken")
    event.add("summary", "korpen broken")
    event.add("dtstart", datetime.now().date())
    event.add("dtend", datetime.now().date())
    calendar.add_component(event)
    return calendar
