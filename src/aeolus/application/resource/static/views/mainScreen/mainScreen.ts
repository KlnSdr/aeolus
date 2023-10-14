class mainScreen implements Component {
  public render(parent: edomElement) {
    edom.fromTemplate([this.instructions()], parent);
  }

  public instructions(): edomTemplate {
    return {
      tag: "p",
      text: "Hello World!"
    };
  }

  public unload() {}
}
edomRouter.addRoute("/", new mainScreen());
