package aeolus.readings.rest;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.MonthlyValues;
import aeolus.readings.service.MonthlyValuesService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import common.logger.Logger;
import dobby.annotations.Delete;
import dobby.annotations.Get;
import dobby.annotations.Put;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.common.ErrorResponses;

import java.util.*;

import static aeolus.util.IsoDate.isValidIsoDate;
import static aeolus.util.IsoDate.parseIsoDate;
import static hades.common.Util.prependZero;
import static hades.util.UserUtil.getCurrentUserId;

@RegisterFor(MonthlyValuesResource.class)
public class MonthlyValuesResource {
    private static final Logger LOGGER = new Logger(MonthlyValuesResource.class);
    private static final String BASE_PATH = "/rest/monthly-values";
    private final MonthlyValuesService service;

    @Inject
    public MonthlyValuesResource(MonthlyValuesService service) {
        this.service = service;
    }

    @AuthorizedOnly
    @Get(BASE_PATH)
    public void getAll(HttpContext context) {
        final UUID user = getCurrentUserId(context);
        sendResult(context, service.findByOwner(user));
    }

    @AuthorizedOnly
    @Get(BASE_PATH + "/year/{year}")
    public void getForYear(HttpContext context) {
        int year;
        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
        } catch (NumberFormatException e) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid year: " + context.getRequest().getParam("year"));
            return;
        }

        final UUID user = getCurrentUserId(context);
        final MonthlyValues[] values = service.findByOwnerAndYear(user, year);
        sendResult(context, values);
    }

    @AuthorizedOnly
    @Get(BASE_PATH + "/year/{year}/month/{month}")
    public void getForYearAndMonth(HttpContext context) {
        int year;
        int month;
        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
            month = Integer.parseInt(context.getRequest().getParam("month"));
        } catch (NumberFormatException e) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid year or month: " + context.getRequest().getParam("year") + "-" + context.getRequest().getParam("month"));
            return;
        }

        final UUID user = getCurrentUserId(context);
        final MonthlyValues[] values = {service.findByOwnerAndYearAndMonth(user, year, month)};
        sendResult(context, values);
    }

    @AuthorizedOnly
    @Get(BASE_PATH + "/slice/{month}")
    public void getForMonth(HttpContext context) {
        int month;
        try {
            month = Integer.parseInt(context.getRequest().getParam("month"));
        } catch (NumberFormatException e) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid month: " + context.getRequest().getParam("month"));
            return;
        }

        final UUID user = getCurrentUserId(context);
        final MonthlyValues[] values = service.findByOwnerAndMonth(user, month);
        sendResult(context, values);
    }

    @AuthorizedOnly
    @Put(BASE_PATH + "/{year}/{month}")
    public void putForYearAndMonth(HttpContext context) {
        int year;
        int month;
        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
            month = Integer.parseInt(context.getRequest().getParam("month"));
        } catch (NumberFormatException e) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid year or month: " + context.getRequest().getParam("year") + "-" + context.getRequest().getParam("month"));
            return;
        }

        final NewJson body = context.getRequest().getBody();
        if (!validatePutRequest(body)) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid request");
            return;
        }
        final UUID owner = getCurrentUserId(context);
        final String date = year + "-" + prependZero(month) + "-01";
        final int operatingHoursHeating = body.getInt("operatingHoursHeating");
        final int operatingHoursWater = body.getInt("operatingHoursWater");
        final int operatingHoursTwo = body.getInt("operatingHoursTwo");
        final int highTariffPower = body.getInt("highTariffPower");
        final int lowTariffPower = body.getInt("lowTariffPower");
        final int householdPower = body.getInt("householdPower");
        final int householdWater = body.getInt("householdWater");

        if (!isValidIsoDate(date)) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid date: " + date);
            return;
        }

        final MonthlyValues monthlyValues;
        try {
            monthlyValues = service.calculateMonthsValuesFromCumulativeAndUpdateDatabase(
                    new MonthlyValues(
                            owner,
                            parseIsoDate(date),
                            operatingHoursHeating,
                            operatingHoursWater,
                            operatingHoursTwo,
                            highTariffPower,
                            lowTariffPower,
                            householdPower,
                            householdWater
                    )
            );
        } catch (DuplicateEntryException e) {
            ErrorResponses.conflict(context.getResponse(), "Entry for date already exists: " + date);
            return;
        }

        boolean wasAdded;
        try {
            wasAdded = service.update(monthlyValues);
        } catch (DuplicateEntryException e) {
            ErrorResponses.conflict(context.getResponse(), "Entry for date already exists: " + date);
            return;
        }

        if  (!wasAdded) {
            ErrorResponses.internalError(context.getResponse(), "Failed to add monthly values for date: " + date);
            return;
        }
        context.getResponse().setCode(ResponseCodes.CREATED);
        context.getResponse().setBody(monthlyValues.toJson());
    }

    @AuthorizedOnly
    @Put(BASE_PATH + "/temporary")
    public void putForTemporary(HttpContext context) {
        final NewJson body = context.getRequest().getBody();
        if (!validatePutRequest(body)) {
            ErrorResponses.badRequest(context.getResponse(), "Invalid request");
            return;
        }
        final UUID owner = getCurrentUserId(context);
        final String date = "1970-01-01";
        final int operatingHoursHeating = body.getInt("operatingHoursHeating");
        final int operatingHoursWater = body.getInt("operatingHoursWater");
        final int operatingHoursTwo = body.getInt("operatingHoursTwo");
        final int highTariffPower = body.getInt("highTariffPower");
        final int lowTariffPower = body.getInt("lowTariffPower");
        final int householdPower = body.getInt("householdPower");
        final int householdWater = body.getInt("householdWater");

        final MonthlyValues temporary = new MonthlyValues(
                owner,
                parseIsoDate(date),
                operatingHoursHeating,
                operatingHoursWater,
                operatingHoursTwo,
                highTariffPower,
                lowTariffPower,
                householdPower,
                householdWater
        );

        boolean wasAdded = service.updateTemporary(temporary);

        if  (!wasAdded) {
            ErrorResponses.internalError(context.getResponse(), "Failed to set temporary monthly values");
            return;
        }
        context.getResponse().setCode(ResponseCodes.OK);
    }

    @AuthorizedOnly
    @Delete(BASE_PATH)
    public void resetData(HttpContext context) {
        final UUID user = getCurrentUserId(context);
        boolean success = service.reset(user);
        if (!success) {
            ErrorResponses.internalError(context.getResponse(), "Failed to reset monthly values");
            return;
        }
        context.getResponse().setCode(ResponseCodes.OK);
    }

    private void sendResult(HttpContext context, MonthlyValues[] values) {
        Arrays.sort(values, Comparator.comparing(MonthlyValues::getDate));

        final NewJson json = new NewJson();
        List<Object> readingsList = List.of(Arrays.stream(values).map(MonthlyValues::toJson).toArray(NewJson[]::new));
        json.setList("readings", readingsList);
        context.getResponse().setBody(json);
    }

    private boolean validatePutRequest(NewJson json) {
        if (!(json != null && json.hasKeys("operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "highTariffPower", "lowTariffPower", "householdPower", "householdWater"))) {
            return false;
        }

        return json.getIntKeys().containsAll(List.of("operatingHoursHeating", "operatingHoursWater", "operatingHoursTwo", "highTariffPower", "lowTariffPower", "householdPower", "householdWater"));
    }
}
