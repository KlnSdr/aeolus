package aeolus.readings.service;

import aeolus.readings.TariffPrices;
import common.inject.api.Inject;
import common.inject.api.RegisterFor;
import dobby.util.json.NewJson;
import thot.connector.IConnector;
import thot.janus.Janus;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RegisterFor(TariffService.class)
public class TariffService {
    public static final String BUCKET_NAME = "aeolus_tariffPrices";
    private final IConnector connector;

    @Inject
    public TariffService(IConnector connector) {
        this.connector = connector;
    }

    public boolean update(TariffPrices tariffPrices) {
        return connector.write(TariffService.BUCKET_NAME, tariffPrices.getKey(), tariffPrices.toJson());
    }

    public Optional<TariffPrices> findByOwnerAndYear(String owner, int year) {
        final String key = owner + "_" + year;
        final TariffPrices tariffPrices = Janus.parse(connector.read(TariffService.BUCKET_NAME, key, NewJson.class), TariffPrices.class);
        if (tariffPrices == null) {
            return Optional.empty();
        }
        return Optional.of(tariffPrices);
    }

    public TariffPrices[] findByOwner(UUID owner) {
        final NewJson[] jsonResults = connector.readPattern(BUCKET_NAME, owner + "_[0-9][0-9][0-9][0-9]", NewJson.class);
        final List<TariffPrices> results = new ArrayList<>();
        for (NewJson jsonResult : jsonResults) {
            final TariffPrices tariffPrices = Janus.parse(jsonResult, TariffPrices.class);
            if (tariffPrices != null) {
                results.add(tariffPrices);
            }
        }
        return results.toArray(new TariffPrices[0]);
    }
}
