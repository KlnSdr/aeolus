package aeolus.readings.rest;

import aeolus.readings.TariffPrices;
import aeolus.readings.service.TariffService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.annotations.Get;
import dobby.annotations.Put;
import dobby.io.HttpContext;
import dobby.io.response.ResponseCodes;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;

import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

import static hades.util.UserUtil.getCurrentUserId;

@RegisterFor(TariffPricesResource.class)
public class TariffPricesResource {
    private static final String BASE_PATH = "/rest/tariff-prices";
    private final TariffService tariffService;

    @Inject
    public TariffPricesResource(TariffService tariffService) {
        this.tariffService = tariffService;
    }

    @ApiDoc(description = "Retrieves all tariff prices for the current user. The endpoint returns an array of tariff prices sorted by year.", summary = "Get all Tariff Prices sorted by year.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "Successful operation.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    @AuthorizedOnly
    @Get(BASE_PATH)
    public void getAll(HttpContext context) {
        final UUID user = getCurrentUserId(context);
        sendResult(context, tariffService.findByOwner(user));
    }

    @ApiDoc(description = "Creates or updates the tariff prices for the specified year. The year must be a valid integer. The request body must contain the following non-negative integer fields: centsHighTariff, centsLowTariff, centsHouseholdPower.", summary = "Create or update tariff prices for a specific year.", baseUrl = BASE_PATH)
    @ApiResponse(code = 201, message = "Successful operation.")
    @ApiResponse(code = 400, message = "Invalid year parameter or request body.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    @AuthorizedOnly
    @Put(BASE_PATH + "/{year}")
    public void update(HttpContext context) {
        final int year;

        try {
            year = Integer.parseInt(context.getRequest().getParam("year"));
        } catch (NumberFormatException e) {
            context.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            return;
        }

        final NewJson json = context.getRequest().getBody();
        if (!validateCreateBody(json)) {
            context.getResponse().setCode(ResponseCodes.BAD_REQUEST);
            return;
        }
        final TariffPrices prices = new TariffPrices();
        prices.setOwner(getCurrentUserId(context));
        prices.setYear(year);
        prices.setCentsHighTariff(json.getInt("centsHighTariff"));
        prices.setCentsLowTariff(json.getInt("centsLowTariff"));
        prices.setCentsHouseholdPower(json.getInt("centsHouseholdPower"));

        if (!tariffService.update(prices)) {
            context.getResponse().setCode(ResponseCodes.INTERNAL_SERVER_ERROR);
            return;
        }
        context.getResponse().setCode(ResponseCodes.CREATED);
    }

    private boolean validateCreateBody(NewJson body) {
        if (!body.hasKeys("centsHighTariff", "centsLowTariff", "centsHouseholdPower")) {
            return false;
        }

        return body.getInt("centsHighTariff") != null
                && body.getInt("centsLowTariff") != null
                && body.getInt("centsHouseholdPower") != null
                && body.getInt("centsHighTariff") >= 0
                && body.getInt("centsLowTariff") >= 0
                && body.getInt("centsHouseholdPower") >= 0;
    }

    private void sendResult(HttpContext context, TariffPrices[] values) {
        Arrays.sort(values, Comparator.comparing(TariffPrices::getYear));

        final NewJson json = new NewJson();
        List<Object> readingsList = List.of(Arrays.stream(values).map(TariffPrices::toJson).toArray(NewJson[]::new));
        json.setList("readings", readingsList);
        context.getResponse().setBody(json);
    }
}
