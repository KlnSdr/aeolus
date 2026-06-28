package aeolus.readings;

import dobby.util.json.NewJson;
import thot.janus.DataClass;
import thot.janus.annotations.JanusString;
import thot.janus.annotations.JanusUUID;

import java.util.UUID;

public class LastReading implements DataClass {
    @JanusUUID("owner")
    private UUID owner;
    @JanusString("key")
    private String key;

    public UUID getOwner() {
        return owner;
    }

    public void setOwner(UUID owner) {
        this.owner = owner;
    }

    @Override
    public String getKey() {
        return owner.toString();
    }

    public void setForeignKey(String key) {
        this.key = key;
    }

    public String getForeignKey() {
        return key;
    }

    @Override
    public NewJson toJson() {
        final NewJson json = new NewJson();
        json.setString("owner", owner.toString());
        json.setString("key", key);
        return json;
    }
}
