package aeolus.readings.quality;

import aeolus.readings.quality.service.CheckerConfigService;
import dobby.util.json.NewJson;
import janus.DataClass;
import janus.annotations.JanusBoolean;
import janus.annotations.JanusInteger;
import janus.annotations.JanusString;
import janus.annotations.JanusUUID;
import thot.annotations.v2.Bucket;

import java.util.UUID;

@Bucket(CheckerConfigService.BUCKET_NAME)
public class CheckerConfig implements DataClass {
    @JanusUUID("userId")
    private UUID userId;
    @JanusBoolean("enabled")
    private boolean enabled;
    @JanusInteger("startHour")
    private int startHour;
    @JanusInteger("startMinute")
    private int startMinute;
    @JanusInteger("lastRunDay")
    private int lastRunDay;
    @JanusInteger("lastRunMonth")
    private int lastRunMonth;
    @JanusInteger("lastRunYear")
    private int lastRunYear;
    @JanusInteger("lastRunHour")
    private int lastRunHour;
    @JanusInteger("lastRunMinute")
    private int lastRunMinute;
    @JanusString("lastRunStatus")
    private String lastRunStatus;

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public int getStartHour() {
        return startHour;
    }

    public void setStartHour(int startHour) {
        this.startHour = startHour;
    }

    public int getStartMinute() {
        return startMinute;
    }

    public void setStartMinute(int startMinute) {
        this.startMinute = startMinute;
    }

    public int getLastRunDay() {
        return lastRunDay;
    }

    public void setLastRunDay(int lastRunDay) {
        this.lastRunDay = lastRunDay;
    }

    public int getLastRunMonth() {
        return lastRunMonth;
    }

    public void setLastRunMonth(int lastRunMonth) {
        this.lastRunMonth = lastRunMonth;
    }

    public int getLastRunYear() {
        return lastRunYear;
    }

    public void setLastRunYear(int lastRunYear) {
        this.lastRunYear = lastRunYear;
    }

    public int getLastRunHour() {
        return lastRunHour;
    }

    public void setLastRunHour(int lastRunHour) {
        this.lastRunHour = lastRunHour;
    }

    public int getLastRunMinute() {
        return lastRunMinute;
    }

    public void setLastRunMinute(int lastRunMinute) {
        this.lastRunMinute = lastRunMinute;
    }

    public CheckerStatus getLastRunStatus() {
        return CheckerStatus.valueOf(lastRunStatus);
    }

    public void setLastRunStatus(CheckerStatus lastRunStatus) {
        this.lastRunStatus = lastRunStatus.toString();
    }

    @Override
    public String getKey() {
        return userId.toString();
    }

    @Override
    public NewJson toJson() {
        final NewJson json = new NewJson();
        json.setString("userId", userId.toString());
        json.setBoolean("enabled", enabled);
        json.setInt("startHour", startHour);
        json.setInt("startMinute", startMinute);
        json.setInt("lastRunDay", lastRunDay);
        json.setInt("lastRunMonth", lastRunMonth);
        json.setInt("lastRunYear", lastRunYear);
        json.setInt("lastRunHour", lastRunHour);
        json.setInt("lastRunMinute", lastRunMinute);
        json.setString("lastRunStatus", lastRunStatus);
        return json;
    }

    public NewJson toStoreJson() {
        final NewJson json = new NewJson();
        json.setString("userId", userId.toString());
        json.setString("enabled", enabled ? "true": "false");
        json.setInt("startHour", startHour);
        json.setInt("startMinute", startMinute);
        json.setInt("lastRunDay", lastRunDay);
        json.setInt("lastRunMonth", lastRunMonth);
        json.setInt("lastRunYear", lastRunYear);
        json.setInt("lastRunHour", lastRunHour);
        json.setInt("lastRunMinute", lastRunMinute);
        json.setString("lastRunStatus", lastRunStatus);
        return json;
    }
}
