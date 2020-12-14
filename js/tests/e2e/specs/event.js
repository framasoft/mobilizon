beforeEach(() => {
  cy.clearLocalStorage();
});

describe("Events", () => {
  it("Shows my current events", () => {
    const EVENT = { title: "My first event" };

    cy.loginUser();
    cy.visit("/events/me");
    cy.contains(".message.is-danger", "No events found");
    cy.contains(".navbar-item", "Create").click();

    cy.url().should("include", "create");
    cy.get(".field").first().find("input").type(EVENT.title);
    cy.get(".field").eq(1).find("input").type("my tag, holo{enter}");
    cy.get(".field").eq(2).find(".datepicker .dropdown-trigger").click();

    cy.get(".field")
      .eq(3)
      .find(".pagination-list .control")
      .first()
      .find(".select select")
      .select("September");
    cy.get(".field")
      .eq(3)
      .find(".pagination-list .control")
      .last()
      .find(".select select")
      .select("2021");
    cy.get(".field").eq(3).contains(".datepicker-cell", "15").click();

    cy.contains(".button.is-primary", "Create my event").click();
    cy.url().should("include", "/events/");
    cy.contains(".title", EVENT.title);
    cy.contains(".column.is-3-tablet", "One person going");
    cy.get(".eventMetadataBlock")
      .eq(1)
      .contains("On Wednesday, September 15, 2021 from");
    cy.contains(".column.is-3-tablet", "Public event");

    cy.contains(".navbar-item", "My events").click();
    cy.contains(".title", EVENT.title);
    cy.contains(".content.column", "Organized by I'm a test user");
    cy.contains(
      ".title-wrapper .date-component .datetime-container .month",
      "Sep"
    );
    cy.contains(
      ".title-wrapper .date-component .datetime-container .day",
      "15"
    );
  });
});
