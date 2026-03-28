package aeolus.reports.rendering.dto;

import dobby.util.json.NewJson;

import java.text.DecimalFormat;

public class TableValuesDTO {
    private int operatingHoursHeating;
    private float averageOperatingHoursHeating;
    private int operatingHoursWater;
    private float averageOperatingHoursWater;
    private int operatingHoursTwo;
    private float averageOperatingHoursTwo;
    private int highTariffPower;
    private float averageHighTariffPower;
    private int lowTariffPower;
    private float averageLowTariffPower;
    private int householdPower;
    private float averageHouseholdPower;
    private int householdWater;
    private float averageHouseholdWater;
    private float temperatureAverage;
    private float averageTemperatureAverage;
    private float temperatureMax;
    private float averageTemperatureMax;
    private float temperatureMin;
    private float averageTemperatureMin;

    public int getOperatingHoursHeating() {
        return operatingHoursHeating;
    }

    public void setOperatingHoursHeating(int operatingHoursHeating) {
        this.operatingHoursHeating = operatingHoursHeating;
    }

    public float getAverageOperatingHoursHeating() {
        return averageOperatingHoursHeating;
    }

    public void setAverageOperatingHoursHeating(float averageOperatingHoursHeating) {
        this.averageOperatingHoursHeating = averageOperatingHoursHeating;
    }

    public int getOperatingHoursWater() {
        return operatingHoursWater;
    }

    public void setOperatingHoursWater(int operatingHoursWater) {
        this.operatingHoursWater = operatingHoursWater;
    }

    public float getAverageOperatingHoursWater() {
        return averageOperatingHoursWater;
    }

    public void setAverageOperatingHoursWater(float averageOperatingHoursWater) {
        this.averageOperatingHoursWater = averageOperatingHoursWater;
    }

    public int getOperatingHoursTwo() {
        return operatingHoursTwo;
    }

    public void setOperatingHoursTwo(int operatingHoursTwo) {
        this.operatingHoursTwo = operatingHoursTwo;
    }

    public float getAverageOperatingHoursTwo() {
        return averageOperatingHoursTwo;
    }

    public void setAverageOperatingHoursTwo(float averageOperatingHoursTwo) {
        this.averageOperatingHoursTwo = averageOperatingHoursTwo;
    }

    public int getHighTariffPower() {
        return highTariffPower;
    }

    public void setHighTariffPower(int highTariffPower) {
        this.highTariffPower = highTariffPower;
    }

    public float getAverageHighTariffPower() {
        return averageHighTariffPower;
    }

    public void setAverageHighTariffPower(float averageHighTariffPower) {
        this.averageHighTariffPower = averageHighTariffPower;
    }

    public int getLowTariffPower() {
        return lowTariffPower;
    }

    public void setLowTariffPower(int lowTariffPower) {
        this.lowTariffPower = lowTariffPower;
    }

    public float getAverageLowTariffPower() {
        return averageLowTariffPower;
    }

    public void setAverageLowTariffPower(float averageLowTariffPower) {
        this.averageLowTariffPower = averageLowTariffPower;
    }

    public int getHouseholdPower() {
        return householdPower;
    }

    public void setHouseholdPower(int householdPower) {
        this.householdPower = householdPower;
    }

    public float getAverageHouseholdPower() {
        return averageHouseholdPower;
    }

    public void setAverageHouseholdPower(float averageHouseholdPower) {
        this.averageHouseholdPower = averageHouseholdPower;
    }

    public int getHouseholdWater() {
        return householdWater;
    }

    public void setHouseholdWater(int householdWater) {
        this.householdWater = householdWater;
    }

    public float getAverageHouseholdWater() {
        return averageHouseholdWater;
    }

    public void setAverageHouseholdWater(float averageHouseholdWater) {
        this.averageHouseholdWater = averageHouseholdWater;
    }

    public float getTemperatureAverage() {
        return temperatureAverage;
    }

    public void setTemperatureAverage(float temperatureAverage) {
        this.temperatureAverage = temperatureAverage;
    }

    public float getAverageTemperatureAverage() {
        return averageTemperatureAverage;
    }

    public void setAverageTemperatureAverage(float averageTemperatureAverage) {
        this.averageTemperatureAverage = averageTemperatureAverage;
    }

    public float getTemperatureMax() {
        return temperatureMax;
    }

    public void setTemperatureMax(float temperatureMax) {
        this.temperatureMax = temperatureMax;
    }

    public float getAverageTemperatureMax() {
        return averageTemperatureMax;
    }

    public void setAverageTemperatureMax(float averageTemperatureMax) {
        this.averageTemperatureMax = averageTemperatureMax;
    }

    public float getTemperatureMin() {
        return temperatureMin;
    }

    public void setTemperatureMin(float temperatureMin) {
        this.temperatureMin = temperatureMin;
    }

    public float getAverageTemperatureMin() {
        return averageTemperatureMin;
    }

    public void setAverageTemperatureMin(float averageTemperatureMin) {
        this.averageTemperatureMin = averageTemperatureMin;
    }

    public NewJson toJson() {
        final NewJson json = new NewJson();
        final DecimalFormat df = new DecimalFormat();
        df.setMaximumFractionDigits(1);

        json.setString("operatingHoursHeating", df.format(operatingHoursHeating));
        json.setString("averageOperatingHoursHeating", df.format(averageOperatingHoursHeating));
        json.setString("operatingHoursWater", df.format(operatingHoursWater));
        json.setString("averageOperatingHoursWater", df.format(averageOperatingHoursWater));
        json.setString("operatingHoursTwo", df.format(operatingHoursTwo));
        json.setString("averageOperatingHoursTwo", df.format(averageOperatingHoursTwo));
        json.setString("highTariffPower", df.format(highTariffPower));
        json.setString("averageHighTariffPower", df.format(averageHighTariffPower));
        json.setString("lowTariffPower", df.format(lowTariffPower));
        json.setString("averageLowTariffPower", df.format(averageLowTariffPower));
        json.setString("householdPower", df.format(householdPower));
        json.setString("averageHouseholdPower", df.format(averageHouseholdPower));
        json.setString("householdWater", df.format(householdWater));
        json.setString("averageHouseholdWater", df.format(averageHouseholdWater));
        json.setString("temperatureAverage", df.format(temperatureAverage));
        json.setString("averageTemperatureAverage", df.format(averageTemperatureAverage));
        json.setString("temperatureMax", df.format(temperatureMax));
        json.setString("averageTemperatureMax", df.format(averageTemperatureMax));
        json.setString("temperatureMin", df.format(temperatureMin));
        json.setString("averageTemperatureMin", df.format(averageTemperatureMin));
        return json;
    }
}
