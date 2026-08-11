package aeolus.readings.quality.rest;

import aeolus.exceptions.DuplicateEntryException;
import aeolus.readings.Reading;
import aeolus.readings.quality.InterpolationService;
import aeolus.readings.service.ReadingService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.annotations.Get;
import dobby.annotations.Post;
import dobby.io.HttpContext;
import dobby.util.Tupel;
import dobby.util.json.NewJson;
import hades.annotations.AuthorizedOnly;
import hades.apidocs.annotations.ApiDoc;
import hades.apidocs.annotations.ApiResponse;
import hades.util.UserUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static aeolus.util.IsoDate.toIsoDateString;

@RegisterFor(InterpolationResource.class)
public class InterpolationResource {
    private static final String BASE_PATH = "/rest/interpolation";
    private final InterpolationService service;
    private final ReadingService readingService;

    @Inject
    public InterpolationResource(InterpolationService service, ReadingService readingService) {
        this.service = service;
        this.readingService = readingService;
    }

    @AuthorizedOnly
    @Post(BASE_PATH)
    @ApiDoc(description = "Interpolates missing readings (holes) for the current user based on their data.", summary = "Interpolate missing readings for the current user.", baseUrl = BASE_PATH)
    @ApiResponse(code = 200, message = "The interpolated readings and holes that could not be interpolated.")
    @ApiResponse(code = 401, message = "Unauthorized access.")
    @ApiResponse(code = 500, message = "Internal server error.")
    public void getInterpolation(HttpContext context) {
        final UUID userId = UserUtil.getCurrentUserId(context);
        final Tupel<List<Reading>, List<String>> result = service.interpolate(userId);
        final List<Reading> savedReadings = new ArrayList<>();
        for (Reading reading : result._1()) {
            try {
                if (readingService.add(reading)) {
                    savedReadings.add(reading);
                } else {
                    break;
                }
            } catch (DuplicateEntryException e) {
                break;
            }
        }

        final List<String> notInterpolatedHoles = new ArrayList<>(result._2());
        for (Reading reading : result._1()) {
            if (!savedReadings.contains(reading)) {
                notInterpolatedHoles.add(toIsoDateString(reading.getDate()));
            }
        }

        final NewJson response = new NewJson();
        response.setList("interpolatedReadings", savedReadings.stream().map(r -> (Object) r.toJson()).toList());
        response.setList("notInterpolatedHoles", notInterpolatedHoles.stream().map(hole -> (Object) hole).toList());

        context.getResponse().setBody(response);
    }
}
