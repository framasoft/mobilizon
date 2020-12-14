import onBeforeLoad from "./browser-language";

beforeEach(() => {
  cy.clearLocalStorage();
});

describe("Login", () => {
  it("Tests that everything is present", () => {
    cy.visit("/login", { onBeforeLoad });

    cy.get("form .field").first().contains("label", "Email");
    cy.get("form .field").last().contains("label", "Password");
    cy.get("form").contains("button.button", "Login");
    cy.get("form")
      .contains(".control a.button", "Forgot your password ?")
      .click();
    cy.url().should("include", "/password-reset/send");
    cy.go("back");

    cy.get("form").contains(".control a.button", "Register").click();
    cy.url().should("include", "/register/user");

    cy.go("back");
  });

  it("Tries to login with incorrect credentials", () => {
    cy.visit("/login", { onBeforeLoad });
    cy.get("input[type=email]")
      .type("notanemail")
      .should("have.value", "notanemail");
    cy.get("input[type=password]").click();
    cy.contains("button.button.is-primary.is-large", "Login").click();
    // cy.get('form .field').first().contains('p.help.is-danger', '@');
  });

  it("Tries to login with invalid credentials", () => {
    cy.visit("/login", { onBeforeLoad });
    cy.get("input[type=email]")
      .type("test@email.com")
      .should("have.value", "test@email.com");
    cy.get("input[type=password]")
      .type("badPassword")
      .should("have.value", "badPassword");
    cy.contains("button.button.is-primary.is-large", "Login").click();

    cy.contains(
      ".message.is-danger",
      "No user account with this email was found. Maybe you made a typo?"
    );
  });

  it("Tries to login with valid credentials", () => {
    cy.visit("/login", { onBeforeLoad });
    cy.get("input[type=email]").type("user@email.com");
    cy.get("input[type=password]").type("some password");
    cy.get("form").submit();
    cy.get(".navbar-end .navbar-link span.icon i").should(
      "have.class",
      "mdi-account-circle"
    );
    cy.contains("article.message.is-info", "Welcome back I'm a test user");
    cy.get(".navbar-item.has-dropdown").click();
    cy.get(".navbar-item").last().contains("Log out").click();
  });

  it("Tries to login with valid credentials but unconfirmed account", () => {
    cy.visit("/login", { onBeforeLoad });
    cy.get("input[type=email]").type("unconfirmed@email.com");
    cy.get("input[type=password]").type("some password");
    cy.get("form").submit();
    cy.contains(
      ".message.is-danger",
      "The user account you're trying to login as has not been confirmed yet. Check your email inbox and eventually your spam folder.You may also ask to resend confirmation email."
    );
  });

  it("Tries to login with valid credentials, confirmed account but no profile", () => {
    cy.visit("/login", { onBeforeLoad });
    cy.get("input[type=email]").type("confirmed@email.com");
    cy.get("input[type=password]").type("some password");
    cy.get("form").submit();

    cy.contains(
      ".message",
      "To achieve your registration, please create a first identity profile."
    );
    cy.get("form > .field")
      .eq(1)
      .contains("label", "Username")
      .parent()
      .find("input")
      .type("test_user");
    cy.get("form > .field")
      .first()
      .contains("label", "Display name")
      .parent()
      .find("input")
      .type("Duplicate");
    cy.get("form > .field")
      .eq(2)
      .contains("label", "Description")
      .parent()
      .find("textarea")
      .type("This shouln't work because it' using a dupublicated username");
    cy.get(".control.has-text-centered")
      .contains("button", "Create my profile")
      .click();
    cy.contains(".help.is-danger", "This username is already taken.");

    cy.get("form .field input").first(0).clear().type("test_user_2");
    cy.get("form .field input").eq(1).type("Not");
    cy.get("form .field textarea").clear().type("This will now work");
    cy.get("form").submit();

    cy.get(".navbar-link span.icon i").should(
      "have.class",
      "mdi-account-circle"
    );
    cy.contains(
      "article.message.is-info",
      "Welcome to Mobilizon, test_user_2!"
    );
  });
});
