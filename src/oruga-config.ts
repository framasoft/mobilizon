export const orugaConfig = {
  iconPack: "",
  iconComponent: "material-icon",
  statusIcon: true,
  button: {
    rootClass: "btn",
    variantClass: (variant: string) => {
      return `btn-${variant}`;
    },
    roundedClass: "btn-rounded",
    outlinedClass: (variant: string) => {
      return `btn-outlined-${variant}`;
    },
    disabledClass: "btn-disabled",
    sizeClass: (size: string) => {
      return `"btn-size-${size}`;
    },
  },
  field: {
    rootClass: "field",
    labelClass: "field-label",
    messageClass: "text-sm italic",
    variantMessageClass: (variant: string) => {
      return `field-message-${variant}`;
    },
  },
  input: {
    inputClass: "input",
    roundedClass: "rounded",
    variantClass: (variant: string) => {
      return `input-${variant}`;
    },
    iconRightClass: "input-icon-right",
    sizeClass: (size: string) => {
      return `input-size-${size}`;
    },
  },
  taginput: {
    itemClass: "taginput-item",
    rootClass: "taginput",
    containerClass: "taginput-container",
    expandedClass: "taginput-expanded",
    autocompleteClasses: {
      rootClass: "taginput-autocomplete",
      itemClass: "taginput-autocomplete-item",
      inputClasses: {
        rootClass: "taginput-input-wrapper",
        inputClass: "taginput-input",
      },
    },
  },
  autocomplete: {
    rootClass: "autocomplete",
    itemClass: "autocomplete-item",
    itemGroupTitleClass: "autocomplete-item-group-title",
  },
  icon: {
    variantClass: (variant: string) => {
      return `icon-${variant}`;
    },
  },
  checkbox: {
    rootClass: "checkbox",
    inputClass: "checkbox-check",
    inputCheckedClass: "checkbox-checked",
    labelClass: "checkbox-label",
  },
  dropdown: {
    rootClass: "dropdown",
    menuClass: "dropdown-menu",
    itemClass: "dropdown-item",
    itemActiveClass: "dropdown-item-active",
  },
  steps: {
    itemHeaderActiveClass: "steps-nav-item-active",
    itemHeaderPreviousClass: "steps-nav-item-previous",
    stepMarkerClass: "step-marker",
    stepDividerClass: "step-divider",
  },
  datepicker: {
    iconNext: "ChevronRight",
    iconPrev: "ChevronLeft",
    boxClass: "datepicker-box",
  },
  modal: {
    rootClass: "modal",
    contentClass: "modal-content",
  },
  switch: {
    labelClass: "switch-label",
    switchCheckedClass: "switch-check-checked",
  },
  select: {
    selectClass: "select",
  },
  radio: {
    rootClass: "radio",
    inputCheckedClass: "radio-checked",
    inputClass: "form-radio",
    labelClass: "radio-label",
  },
  notification: {
    rootClass: "notification",
    variantClass: (variant: string) => {
      return `notification-${variant}`;
    },
  },
  table: {
    tableClass: "table",
    tdClass: "table-td",
    thClass: "table-th",
    rootClass: "table-root",
  },
  pagination: {
    rootClass: "pagination",
    simpleClass: "pagination-simple",
    listClass: "pagination-list",
    infoClass: "pagination-info",
    linkClass: "pagination-link",
    linkCurrentClass: "pagination-link-current",
    linkDisabledClass: "pagination-link-disabled",
    nextButtonClass: "pagination-next",
    prevButtonClass: "pagination-previous",
    ellipsisClass: "pagination-ellipsis",
  },
  tabs: {
    rootClass: "tabs",
    navTabsClass: "tabs-nav",
    navTypeClass: (type: string) => {
      return `tabs-nav-${type}`;
    },
    navSizeClass: (size: string) => {
      return `tabs-nav-${size}`;
    },
    itemWrapperClass: "tabs-nav-item-wrapper",
    itemHeaderTypeClass: (type: string) => {
      return `tabs-nav-item-${type}`;
    },
    itemHeaderActiveClass: "tabs-nav-item-active",
  },
  tooltip: {
    rootClass: "tooltip",
    contentClass: "tooltip-content",
    arrowClass: "tooltip-arrow",
    variantClass: (variant: string) => {
      return `tooltip-content-${variant}`;
    },
  },
};
