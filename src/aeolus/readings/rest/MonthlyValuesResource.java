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
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;
import hades.apidocs.annotations.ApiResponses;
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

    @ApiDoc(description = "Retrieves all monthly values for the current user. The endpoint returns an array of monthly values sorted by date.", summary = "Get all Monthly Values sorted by date.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "Successful operation.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    @AuthorizedOnly
    @Get(BASE_PATH)
    public void getAll(HttpContext context) {
        final UUID user = getCurrentUserId(context);
        sendResult(context, service.findByOwner(user));
    }

    @ApiDoc(description = "Retrieves all monthly values of the provided year for the current user. The endpoint returns an array of monthly values sorted by date.", summary = "Get all Monthly Values for {year} sorted by date.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "Successful operation.")
    @ApiResponse(code = 400, message = "Invalid year parameter.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
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

    @ApiDoc(description = "Retrieves all monthly values for the specified year and month. The year must be a valid integer. The endpoint returns an array of monthly values for the given year, sorted by date.", summary = "Get monthly values for a specific year and month.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "Successful operation.")
    @ApiResponse(code = 400, message = "Invalid year or month parameter.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
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

    @ApiDoc(description = "Retrieves all monthly values for the specified month across all years. The month must be a valid integer between 1 and 12. The endpoint returns an array of monthly values for the given month, sorted by date.", summary = "Get monthly values for a specific month across all years.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "Successful operation.")
    @ApiResponse(code = 400, message = "Invalid month parameter.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
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

    @ApiDoc(description = "Adds monthly values for the specified year and month. The year must be a valid integer and the month must be a valid integer between 1 and 12. The request body must contain the following integer fields: operatingHoursHeating, operatingHoursWater, operatingHoursTwo, highTariffPower, lowTariffPower, householdPower, householdWater. If an entry for the specified date already exists, an error is returned.", summary = "Add or update monthly values for a specific year and month.", baseUrl = BASE_PATH)
    @ApiResponse(code = 201, message = "Successful operation.")
    @ApiResponse(code = 400, message = "Invalid month or year parameter.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 409, message = "Entry for the specified date already exists.")
    @ApiResponse(code = 500, message = "Internal server error.")
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

    @ApiDoc(description = "Sets the temporary monthly values for the current user. The request body must contain the following integer fields: operatingHoursHeating, operatingHoursWater, operatingHoursTwo, highTariffPower, lowTariffPower, householdPower, householdWater. These temporary values can be used for calculations or previews without affecting the actual stored monthly values.", summary = "Set temporary monthly values for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "Successful operation.")
    @ApiResponse(code = 400, message = "Invalid month or year parameter.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
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
