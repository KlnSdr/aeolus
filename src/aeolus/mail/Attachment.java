package aeolus.mail;

import dobby.files.StaticFile;

public class Attachment {
    private final String name;
    private final StaticFile file;

    public Attachment(String name, StaticFile file) {
        this.name = name;
        this.file = file;
    }

    public String getName() {
        return name;
    }
    public StaticFile getFile() {
        return file;
    }
}
