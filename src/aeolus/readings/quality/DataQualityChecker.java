package aeolus.readings.quality;

import aeolus.readings.Reading;
import aeolus.readings.service.ReadingService;
import aeolus.util.IsoDate;
import common.logger.Logger;
import hades.messaging.Message;
import hades.messaging.service.MessageService;

import java.time.LocalDate;
import java.time.Year;
import java.util.*;
import java.util.stream.Collectors;

public class DataQualityChecker {
    private static final ReadingService readingService = ReadingService.getInstance();
    private static final MessageService messageService = MessageService.getInstance();
    private static final Logger LOGGER = new Logger(DataQualityChecker.class);
    private final UUID userId;

    public DataQualityChecker(UUID userId) {
        this.userId = userId;
    }

    public CheckerStatus runCheck() {
        final String msgCheckToday;
        final List<String> msgFindHoles;

        try {
            msgCheckToday = checkToday().orElse("");
            msgFindHoles = findHoles().orElse(Collections.emptyList());

            if (!msgCheckToday.isEmpty() || !msgFindHoles.isEmpty()) {
                messageService.update(buildMessage(msgCheckToday, msgFindHoles));
                return CheckerStatus.WARNING;
            }
            return CheckerStatus.OK;
        } catch (Exception e) {
            LOGGER.error("an error occurred while checking data integrity");
            LOGGER.trace(e);
            return CheckerStatus.ERROR;
        }
    }

    private Message buildMessage(String msgCheckToday, List<String> holes) {
        final StringBuilder message = new StringBuilder();

        if (!msgCheckToday.isEmpty()) {
            message.append(msgCheckToday).append("\\n");
        }

        if (!holes.isEmpty()) {
            message.append("Holes in data (").append(holes.size()).append("):\\n");
            for (String hole : holes) {
                message.append(hole).append("\\n");
            }
        }

        return messageService.newSystemMessage(userId, message.toString());
    }

    private Optional<String> checkToday() {
        final Calendar now = Calendar.getInstance();
        try {
            readingService.find(userId, now.get(Calendar.YEAR), now.get(Calendar.MONTH) + 1, now.get(Calendar.DAY_OF_MONTH));
            return Optional.empty();
        } catch (NullPointerException e) {
            return Optional.of("Missing entry for " + now.get(Calendar.YEAR) + "-" + (now.get(Calendar.MONTH) + 1) + "-" + now.get(Calendar.DAY_OF_MONTH));
        }
    }

    private Optional<List<String>> findHoles() {
        int year = Year.now().getValue();
        int yearsWithoutData = 0;
        final Map<Integer, List<String>> holes = new HashMap<>();
        while (yearsWithoutData < 2) {
            LOGGER.debug("checking " + year);
            final Reading[] readings = readingService.find(userId, year);

            if (readings.length == 0) {
                yearsWithoutData++;
                LOGGER.debug("no data for " + year);
                year--;
                continue;
            } else {
                yearsWithoutData = 0;
            }

            if ((Year.isLeap(year) && readings.length != 366) || (!Year.isLeap(year) && readings.length != 365)) {
                holes.put(year, findHoles(year, readings));
            }

            year--;
        }

        final List<String> result = new ArrayList<>();

        for (Map.Entry<Integer, List<String>> entry : holes.entrySet()) {
            result.addAll(entry.getValue());
        }

        if (result.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(result);
    }

    private List<String> findHoles(int year, Reading[] readings) {
        final List<String> holes = new ArrayList<>();

        final LocalDate firstDayOfYear = LocalDate.of(year, 1, 1);
        LocalDate lastDayOfYear = LocalDate.of(year, 12, 31);

        if (LocalDate.now().isBefore(lastDayOfYear)) {
            lastDayOfYear = LocalDate.now();
        }

        final List<String> datesOfYear =  firstDayOfYear.datesUntil(lastDayOfYear.plusDays(1)).filter(d -> d.isBefore(LocalDate.now())).map(LocalDate::toString).toList();

        final Set<String> datesWithValues = Arrays.stream(readings).map(Reading::getDate).map(IsoDate::toIsoDateString).collect(Collectors.toSet());

        for (String date : datesOfYear) {
            if (!datesWithValues.contains(date)) {
                holes.add(date);
            }
        }

        return holes;
    }
}
