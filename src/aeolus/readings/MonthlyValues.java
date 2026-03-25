package aeolus.readings;

import aeolus.util.IsoDate;
import dobby.util.json.NewJson;
import thot.janus.DataClass;
import thot.janus.annotations.JanusInteger;
import thot.janus.annotations.JanusString;
import thot.janus.annotations.JanusUUID;

import java.util.Date;
import java.util.UUID;

public class MonthlyValues implements DataClass {
    @JanusUUID("owner")
    private UUID owner;
    @JanusString("date")
    private String date;
    @JanusInteger("operatingHoursHeating")
    private int operatingHoursHeating;
    @JanusInteger("operatingHoursWater")
    private int operatingHoursWater;
    @JanusInteger("operatingHoursTwo")
    private int operatingHoursTwo;
    @JanusInteger("highTariffPower")
    private int highTariffPower;
    @JanusInteger("lowTariffPower")
    private int lowTariffPower;
    @JanusInteger("householdPower")
    private int householdPower;
    @JanusInteger("householdWater")
    private int householdWater;

    public MonthlyValues() {
    }

    public MonthlyValues(UUID owner, Date date, int operatingHoursHeating, int operatingHoursWater, int operatingHoursTwo, int highTariffPower, int lowTariffPower, int householdPower, int householdWater) {
        this.owner = owner;
        this.date = IsoDate.toIsoDateString(date);
        this.operatingHoursHeating = operatingHoursHeating;
        this.operatingHoursWater = operatingHoursWater;
        this.operatingHoursTwo = operatingHoursTwo;
        this.highTariffPower = highTariffPower;
        this.lowTariffPower = lowTariffPower;
        this.householdPower = householdPower;
        this.householdWater = householdWater;
    }

    public UUID getOwner() {
        return owner;
    }

    public Date getDate() {
        return IsoDate.parseIsoDate(this.date);
    }

    public void setDate(Date date) {
        this.date = IsoDate.toIsoDateString(date);
    }

    public int getOperatingHoursHeating() {
        return operatingHoursHeating;
    }

    public void setOperatingHoursHeating(int operatingHoursHeating) {
        this.operatingHoursHeating = operatingHoursHeating;
    }

    public int getOperatingHoursWater() {
        return operatingHoursWater;
    }

    public void setOperatingHoursWater(int operatingHoursWater) {
        this.operatingHoursWater = operatingHoursWater;
    }

    public int getOperatingHoursTwo() {
        return operatingHoursTwo;
    }

    public void setOperatingHoursTwo(int operatingHoursTwo) {
        this.operatingHoursTwo = operatingHoursTwo;
    }

    public int getHighTariffPower() {
        return highTariffPower;
    }

    public void setHighTariffPower(int highTariffPower) {
        this.highTariffPower = highTariffPower;
    }

    public int getLowTariffPower() {
        return lowTariffPower;
    }

    public void setLowTariffPower(int lowTariffPower) {
        this.lowTariffPower = lowTariffPower;
    }

    public int getHouseholdPower() {
        return householdPower;
    }

    public void setHouseholdPower(int householdPower) {
        this.householdPower = householdPower;
    }

    public int getHouseholdWater() {
        return householdWater;
    }

    public void setHouseholdWater(int householdWater) {
        this.householdWater = householdWater;
    }

    @Override
    public String getKey() {
        return owner + "_" + date.substring(0, 7);
    }

    @Override
    public NewJson toJson() {
        final NewJson json = new NewJson();
        json.setString("date", date);
        json.setString("owner", owner.toString());
        json.setInt("operatingHoursHeating", operatingHoursHeating);
        json.setInt("operatingHoursWater", operatingHoursWater);
        json.setInt("operatingHoursTwo", operatingHoursTwo);
        json.setInt("highTariffPower", highTariffPower);
        json.setInt("lowTariffPower", lowTariffPower);
        json.setInt("householdPower", householdPower);
        json.setInt("householdWater", householdWater);
        return json;
    }
}
