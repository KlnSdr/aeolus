package aeolus.readings;

import dobby.util.json.NewJson;
import thot.janus.DataClass;
import thot.janus.annotations.JanusInteger;
import thot.janus.annotations.JanusUUID;

import java.util.UUID;

public class TariffPrices implements DataClass {
    @JanusUUID("owner")
    private UUID owner;
    @JanusInteger("year")
    private int year;
    @JanusInteger("centsHighTariff")
    private int centsHighTariff;
    @JanusInteger("centsLowTariff")
    private int centsLowTariff;
    @JanusInteger("centsHouseholdPower")
    private int centsHouseholdPower;

    public UUID getOwner() {
        return owner;
    }

    public void setOwner(UUID owner) {
        this.owner = owner;
    }

    public int getYear() {
        return year;
    }

    public void setYear(int year) {
        this.year = year;
    }

    public int getCentsHighTariff() {
        return centsHighTariff;
    }

    public void setCentsHighTariff(int centsHighTariff) {
        this.centsHighTariff = centsHighTariff;
    }

    public int getCentsLowTariff() {
        return centsLowTariff;
    }

    public void setCentsLowTariff(int centsLowTariff) {
        this.centsLowTariff = centsLowTariff;
    }

    public int getCentsHouseholdPower() {
        return centsHouseholdPower;
    }

    public void setCentsHouseholdPower(int centsHouseholdPower) {
        this.centsHouseholdPower = centsHouseholdPower;
    }

    @Override
    public String getKey() {
        return owner + "_" + year;
    }

    @Override
    public NewJson toJson() {
        final NewJson json = new NewJson();
        json.setString("owner", owner.toString());
        json.setInt("year", year);
        json.setInt("centsHighTariff", centsHighTariff);
        json.setInt("centsLowTariff", centsLowTariff);
        json.setInt("centsHouseholdPower", centsHouseholdPower);
        return json;
    }
}
