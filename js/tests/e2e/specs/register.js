import onBeforeLoad from "./browser-language";

describe("Registration", () => {
  it("Tests that everything is present", () => {
    cy.visit("/register/user", { onBeforeLoad });

    cy.get("form .field").first().contains("label", "Email");
    cy.get("form .field").eq(1).contains("label", "Password");

    cy.get("input[type=email]").click();
    cy.get("input[type=password]").type("short").should("have.value", "short");
    cy.get("form").contains("button.button.is-primary", "Register");

    cy.get("form")
      .contains(".control a.button", "Didn't receive the instructions ?")
      .click();
    cy.url().should("include", "/resend-instructions");
    cy.go("back");

    cy.get("form")
      .get(".control a.button")
      .contains("Login")
      .click({ force: true });
    cy.url().should("include", "/login");

    cy.go("back");
  });

  it("Tests that registration works", () => {
    cy.visit("/register/user", { onBeforeLoad });
    cy.get("input[type=email]").type("user2register@email.com");
    cy.get("input[type=password]").type("userPassword");
    cy.get("form").contains("button.button.is-primary", "Register").click();

    cy.url().should("include", "/register/profile");
    cy.get("form > .field")
      .eq(1)
      .contains("label", "Username")
      .parent()
      .find("input")
      .type("tester");
    cy.get("form > .field")
      .first()
      .contains("label", "Display name")
      .parent()
      .find("input")
      .type("tester account");
    cy.get("form > .field")
      .eq(2)
      .contains("label", "Description")
      .parent()
      .find("textarea")
      .type("This is a test account");
    cy.get(".control.has-text-centered")
      .contains("button", "Create my profile")
      .click();

    cy.contains(
      "article.message.is-success",
      "Your account is nearly ready, tester"
    ).contains("A validation email was sent to user2register@email.com");

    cy.visit("/sent_emails");

    cy.get("iframe")
      .first()
      .iframeLoaded()
      .its("document")
      .getInDocument("a")
      .eq(1)
      .contains("Activate my account")
      .invoke("attr", "href")
      .then((href) => {
        cy.visit(href);
      });

    // cy.url().should('include', '/validate/');
    // cy.contains('Your account is being validated');
    cy.location().should((loc) => {
      expect(loc.pathname).to.eq("/");
    });

    cy.get(".navbar-link span.icon i").should(
      "have.class",
      "mdi-account-circle"
    );
    cy.contains(
      "article.message.is-info",
      "Welcome to Mobilizon, tester account!"
    );
  });
});
