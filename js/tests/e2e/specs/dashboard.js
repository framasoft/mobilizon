// https://docs.cypress.io/api/introduction/api.html
import onBeforeLoad from "./browser-language";

describe("Homepage", () => {
  it("Checks the footer", () => {
    cy.visit("/", { onBeforeLoad });
    cy.get("#mobilizon").find("footer").contains("The Mobilizon Contributors");

    cy.contains("About")
      .should("have.attr", "href")
      .and("eq", "https://joinmobilizon.org");

    cy.contains("License")
      .should("have.attr", "href")
      .and(
        "eq",
        "https://framagit.org/framasoft/mobilizon/blob/master/LICENSE"
      );
  });

  it("Tries to register from the hero section", () => {
    cy.visit("/", { onBeforeLoad });

    cy.get(".hero-body").contains("Sign up").click();
    cy.url().should("include", "/register/user");
  });
  it("Tries to register from the navbar", () => {
    cy.visit("/", { onBeforeLoad });

    cy.get("nav.navbar").contains("Sign up").click();
    cy.url().should("include", "/register/user");
  });

  it("Tries to connect from the navbar", () => {
    cy.visit("/", { onBeforeLoad });

    cy.get("nav.navbar").contains("Log in").click();
    cy.url().should("include", "/login");
  });
});
