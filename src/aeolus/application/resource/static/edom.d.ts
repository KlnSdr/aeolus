declare class edom {
    static body: edomElement;
    private static _allElements;
    static get allElements(): edomElement[];
    static init(): void;
    static newElement(tagName: string): edomElement | edomInputElement | edomAnchorElement | edomListElement | edomImageElement | edomLabelElement | edomTAElement;
    static fromExisting(element: HTMLElement): edomElement;
    private static iterateChildren;
    private static getChildren;
    static findById(id: string): edomElement | edomInputElement | edomAnchorElement | edomListElement | edomImageElement | edomLabelElement | edomTAElement | undefined;
    static break(): edomElement | edomInputElement | edomAnchorElement | edomListElement | edomImageElement | edomLabelElement | edomTAElement;
    static fromTemplate(template: edomTemplate | edomTemplate[], parent?: edomElement | null): void;
}
declare class edomAnchorElement extends edomElement {
    target: string;
    href(location: string): void;
}
declare class edomElement {
    element: HTMLElement;
    children: edomElement[];
    private _text;
    get text(): string;
    set text(text: string);
    parent: edomElement | undefined;
    classes: string[];
    tag: string;
    private _id;
    get id(): string;
    set id(id: string);
    private handlers;
    private values;
    constructor(fromExisting: boolean, tagName: string, existingElement?: HTMLElement | null);
    addChild(child: edomElement): void;
    setProperty(key: string, value: any): void;
    getProperty(key: string): any;
    addClick(identifier: string, func: (self: this) => any): void;
    doClick(): void;
    deleteClick(identifier: string): void;
    addEvent(type: string, identifier: string, action: (self: this) => any): void;
    deleteEvent(type: string, identifier: string): void;
    applyStyle(...className: string[]): void;
    removeStyle(...className: string[]): void;
    hasStyle(...className: string[]): boolean;
    swapStyle(oldClass: string, newClass: string): void;
    delete(isChild?: boolean): boolean;
    enable(): void;
    disable(): void;
    focus(): void;
}
declare class edomElementNullException {
    message: string;
    constructor(message: string);
}
declare class edomImageElement extends edomElement {
    private _src;
    get src(): string;
    set src(src: string);
}
declare class edomInputElement extends edomElement {
    private _value;
    get value(): string;
    set value(val: string);
    private _type;
    get type(): string;
    set type(type: string);
    private _checked;
    get checked(): boolean;
    set checked(state: boolean);
    private _groupID;
    get groupID(): string;
    set groupID(id: string);
    addChange(identifier: string, func: (self: this) => any): void;
    deleteChange(identifier: string): void;
    select(): void;
}
declare class edomLabelElement extends edomElement {
    private _for;
    get for(): string;
    set for(htmlFor: string);
}
declare class edomListElement extends edomElement {
    addEntry(text: string): void;
    addEntryLink(text: string, target: string): void;
    addEntryLink(text: string, clickHandler: (self: edomElement) => void): void;
}
declare class edomRouter {
    private static routes;
    private constructor();
    static goTo(route: string, pushHistory?: boolean): void;
    static setFallback(ui: Component): void;
    static addRoute(path: string, ui: Component): void;
    static rewriteUrl(): void;
    private static decodeUrl;
    private static encodeUrl;
    private static parseQuery;
}
declare class edomTAElement extends edomInputElement {
    setContent(text: string): void;
}
interface handlerObject {
    [id: string]: () => void;
}
interface eObj {
    [key: string]: any;
}
interface handlerPreObject extends Object {
    id: string;
    type: string;
    body: (self: edomElement) => void;
}
interface edomTemplate extends Object {
    tag: string;
    text?: string;
    value?: string;
    id?: string;
    classes?: string[];
    children?: edomTemplate[];
    type?: string;
    checked?: boolean;
    src?: string;
    for?: string;
    groupID?: string;
    target?: string;
    handler?: handlerPreObject[];
}
interface Component {
    render: (parent: edomElement) => void;
    instructions: () => edomTemplate;
    unload: () => void;
}
