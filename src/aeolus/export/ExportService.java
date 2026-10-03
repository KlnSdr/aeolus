package aeolus.export;

import aeolus.readings.MonthlyValues;
import aeolus.readings.Reading;
import aeolus.readings.TariffPrices;
import aeolus.readings.service.MonthlyValuesService;
import aeolus.readings.service.ReadingService;
import aeolus.readings.service.TariffService;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RegisterFor(ExportService.class)
public class ExportService {
    private final ReadingService readingService;
    private final MonthlyValuesService monthlyValuesService;
    private final TariffService tariffService;

    @Inject
    public ExportService(ReadingService readingService, MonthlyValuesService monthlyValuesService, TariffService tariffService) {
        this.readingService = readingService;
        this.monthlyValuesService = monthlyValuesService;
        this.tariffService = tariffService;
    }

    public Export export(UUID owner) {
        final Export export = new Export();

        int year = LocalDate.now().getYear();
        MonthlyValues[] monthlyValues = monthlyValuesService.findByOwnerAndYear(owner, year);
        Reading[] readings = readingService.find(owner, year);
        Optional<TariffPrices> tariffPrices = tariffService.findByOwnerAndYear(owner.toString(), year);

        while (readings.length > 0 || monthlyValues.length > 0 || tariffPrices.isPresent()) {
            export.addAllReadings(List.of(readings));
            export.addAllMonthlyValues(List.of(monthlyValues));
            tariffPrices.ifPresent(export::addTariffPrices);
            year--;
            readings = readingService.find(owner, year);
            monthlyValues = monthlyValuesService.findByOwnerAndYear(owner, year);
            tariffPrices = tariffService.findByOwnerAndYear(owner.toString(), year);
        }

        return export;
    }
}
