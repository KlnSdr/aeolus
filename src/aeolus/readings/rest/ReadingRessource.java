package aeolus.readings.rest;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;
import aeolus.readings.service.ReadingService;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.Json;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;

public class ReadingRessource {

    @Get("/readings/{isoDate}")
    public void getReading(HttpContext context) {
        String isoDate = context.getRequest().getParam("isodate");

        Reading reading;

        try {
            reading = ReadingService.getInstance().find(isoDate);
        } catch (IllegalArgumentException e) {
            context.getResponse().setCode(ResponseCodes.BAD_REQUEST);

            Json message = new Json();
            message.setString("msg", "Invalid ISO date: " + isoDate);

            context.getResponse().setBody(message.toString());
            return;
        } catch (NullPointerException e) {
            context.getResponse().setCode(ResponseCodes.NOT_FOUND);

            Json message = new Json();
            message.setString("msg", "No reading found for date: " + isoDate);

            context.getResponse().setBody(message.toString());
            return;
        }

        Json json = new Json();
        json.setString("value", Float.toString(reading.getValue()));

        context.getResponse().setBody(json.toString());
    }

    @Post("/readings")
    public void addReading(HttpContext context) {
        Json json = context.getRequest().getBody();
        float value = Float.parseFloat(json.getString("value"));
        String isoDate = json.getString("date");
        Date date = parseIsoDate(isoDate);

        Reading reading = new Reading(value, date);
        try {
            ReadingService.getInstance().add(reading);
        } catch (DuplicateEntryException e) {
            context.getResponse().setCode(ResponseCodes.BAD_REQUEST); // todo use conflict once implemented

            Json message = new Json();
            message.setString("msg", "Reading for date " + isoDate + " already exists");

            context.getResponse().setBody(message.toString());
            return;
        }

        context.getResponse().setCode(ResponseCodes.CREATED);
    }

    private Date parseIsoDate(String isoDate) {
        LocalDate localDate = LocalDate.parse(isoDate);
        return Date.from(localDate.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }
}
