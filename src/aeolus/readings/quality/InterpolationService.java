package aeolus.readings.quality;

import aeolus.readings.Reading;
import aeolus.readings.service.ReadingService;
import aeolus.util.IsoDate;
import common.logger.Logger;
import dobby.util.Tupel;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;

public class InterpolationService {
    private static final Logger LOGGER = new Logger(InterpolationService.class);
    private static final ReadingService service = ReadingService.getInstance();
    private static final int MAX_GAP_WIDTH_DAYS = 1;
    private static InterpolationService instance;

    private InterpolationService() {
    }

    public static InterpolationService getInstance() {
        if (instance == null) {
            instance = new InterpolationService();
        }
        return instance;
    }

    /**
     * Interpolates missing readings (holes) for a given user based on their data.
     *
     * This method identifies gaps (holes) in the user's data, calculates the gap width,
     * and attempts to interpolate missing readings if the gap width is within the allowed limit.
     * Interpolated readings are calculated as the average of the readings before and after the gap.
     * Any holes that cannot be interpolated are returned as a separate list.
     *
     * @param userId The UUID of the user whose data is being interpolated.
     * @return A Tupel containing:
     *         - A list of successfully interpolated readings.
     *         - A list of holes that could not be interpolated.
     */
    public Tupel<List<Reading>, List<String>> interpolate(UUID userId) {
        final Optional<List<String>> optHoles = new DataQualityChecker(userId).findHoles();

        if (optHoles.isEmpty()) {
            LOGGER.debug("no holes found for interpolation");
            return new Tupel<>(Collections.emptyList(), Collections.emptyList());
        }
        final List<String> holes = optHoles.get();
        if (holes.isEmpty()) {
            LOGGER.debug("no holes found for interpolation");
            return new Tupel<>(Collections.emptyList(), Collections.emptyList());
        }
        LOGGER.debug("found " + holes.size() + " holes for interpolation");
        final List<Reading> interpolatedReadings = new ArrayList<>();
        final List<String> notInterpolatedHoles = new ArrayList<>();
        for (String hole : holes.stream().sorted(String::compareTo).toList()) {
            LOGGER.debug("interpolating hole: " + hole);
            if (!IsoDate.isValidIsoDate(hole)) {
                LOGGER.warn("invalid ISO date format for hole: " + hole);
                continue;
            }

            final int gapWidth = calculateGapWidth(hole, holes);
            LOGGER.debug("gap width for hole " + hole + ": " + gapWidth);
            if (gapWidth > MAX_GAP_WIDTH_DAYS) {
                LOGGER.debug("gap width for hole " + hole + " is greater than " + MAX_GAP_WIDTH_DAYS + " days. not interpolating");
                notInterpolatedHoles.add(hole);
                continue;
            }

            final LocalDate date = LocalDate.parse(hole);
            final LocalDate prevDate = date.minusDays(1);
            final LocalDate nextDate = date.plusDays(1);
            final Reading prevReading;
            final Reading nextReading;
            try {
                 prevReading = service.find(userId, prevDate.getYear(), prevDate.getMonthValue(), prevDate.getDayOfMonth());
                 nextReading = service.find(userId, nextDate.getYear(), nextDate.getMonthValue(), nextDate.getDayOfMonth());
            } catch (Exception e) {
                LOGGER.debug("failed to retrieve readings for interpolation around date: " + hole + ". not interpolating");
                notInterpolatedHoles.add(hole);
                continue;
            }

            final float interpolatedValue = (float) ((prevReading.getValue() + nextReading.getValue()) / 2.0);
            final Reading interpolatedReading = new Reading(round(interpolatedValue, 1), IsoDate.parseIsoDate(hole), userId);
            interpolatedReadings.add(interpolatedReading);
        }

        for (Reading reading : interpolatedReadings) {
            try {
                LOGGER.debug("interpolating reading for " + IsoDate.toIsoDateString(reading.getDate()) + ": " + reading.getValue());
            } catch (Exception e) {
                LOGGER.error("failed to save interpolated reading for date: " + IsoDate.toIsoDateString(reading.getDate()));
                LOGGER.trace(e);
            }
        }

        for (String hole : notInterpolatedHoles) {
            LOGGER.debug("not interpolated hole: " + hole);
        }

        return new Tupel<>(interpolatedReadings, notInterpolatedHoles);
    }

    private float round(float value, int places) {
        return BigDecimal
            .valueOf(value)
            .setScale(places, RoundingMode.HALF_UP)
            .floatValue();
    }

    private int calculateGapWidth(String hole, List<String> holes) {
        int width = 0;
        LocalDate datePlus = LocalDate.parse(hole);
        while (holes.contains(datePlus.toString())) {
            width++;
            datePlus = datePlus.plusDays(1);
        }

        LocalDate dateMinus = LocalDate.parse(hole).minusDays(1);
        while (holes.contains(dateMinus.toString())) {
            width++;
            dateMinus = dateMinus.minusDays(1);
        }
        return width;
    }
}
