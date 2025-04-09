package aeolus.readings;

import aeolus.util.IsoDate;
import dobby.util.json.NewJson;
import thot.janus.DataClass;
import thot.janus.annotations.JanusString;
import thot.janus.annotations.JanusUUID;

import java.util.Date;
import java.util.UUID;

public class Reading implements DataClass {
    // TODO change correct types once janus supports them
    @JanusString("value")
    private String value;
    @JanusString("date")
    private String date;
    @JanusUUID("owner")
    private UUID owner;

    public Reading(float value, Date date, UUID owner) {
        this.value = Double.toString(value);
        this.date = IsoDate.toIsoDateString(date);
        this.owner = owner;
    }

    public Reading() {

    }

    public double getValue() {
        return Double.parseDouble(this.value);
    }

    public Date getDate() {
        return IsoDate.parseIsoDate(this.date);
    }

    @Override
    public String getKey() {
        return owner + "_" + date;
    }

    public UUID getOwner() {
        return owner;
    }

    @Override
    public NewJson toJson() {
        final NewJson json = new NewJson();
        json.setString("date", date);
        json.setFloat("value", getValue());
        return json;
    }

    public NewJson toStoreJson() {
        final NewJson json = new NewJson();
        json.setString("date", date);
        json.setString("value", value);
        json.setString("owner", owner.toString());
        return json;
    }
}
