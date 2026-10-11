from flask import Flask, make_response
from . import cal
from apscheduler.schedulers.background import BackgroundScheduler
from . import scraper
import logging
import sys
logger = logging.getLogger(__name__)

def create_app():
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    app = Flask(__name__)
    scheduler = BackgroundScheduler()
    logger.info("Create app")

    def renew_calendar():
        logger.info("renew calendar")
        missions = []
        try:
            missions = scraper.get_missions_from_korpen()
        except Exception:
            logger.exception("get events from source failed")
        if missions:
            calendar = cal.from_missions(missions)
        else:
            calendar = cal.broken()

        app.config["calendar"] = calendar
        logger.info("renew calendar done")
    renew_calendar()

    @app.route("/")
    def hello_world():
        logger.info("Request hello world")
        return "<p>hello world</p>"

    @app.route("/badminton.ics")
    def ics():
        logger.info("Request ics")
        response = make_response(app.config["calendar"].to_ical().decode("utf-8"), 200)
        response.mimetype = "text/calendar"
        return response

    scheduler.add_job(renew_calendar, "interval", minutes=60)
    scheduler.start()
    return app
