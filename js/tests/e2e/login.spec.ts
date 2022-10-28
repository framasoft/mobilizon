import { test, expect } from "@playwright/test";

test("Login has everything we need", async ({ page }) => {
  await page.goto("/login");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Login/);

  const forgotPasswordLink = page.locator("a", {
    hasText: "Forgot your password?",
  });

  const reAskInstructionsLink = page.locator("a", {
    hasText: "Didn't receive the instructions?",
  });

  const registerLink = page.locator("a > span > span", {
    hasText: "Create an account",
  });

  await expect(forgotPasswordLink).toBeVisible();
  await expect(reAskInstructionsLink).toBeVisible();
  await expect(registerLink).toBeVisible();

  await expect(page.locator("form .field label").first()).toHaveText("Email");
  await expect(page.locator("form .field label").nth(1)).toHaveText("Password");

  await forgotPasswordLink.click();
  await page.waitForURL("/password-reset/send");
  expect(page.url()).toContain("/password-reset/send");
  await page.goBack();

  await reAskInstructionsLink.click();
  await page.waitForURL("/resend-instructions");
  expect(page.url()).toContain("/resend-instructions");
  await page.goBack();

  await registerLink.click();
  await page.waitForURL("/register/user");
  expect(page.url()).toContain("/register/user");
  await page.goBack();
});

test("Login rejects unknown users properly", async ({ page }) => {
  await page.goto("/login");

  await page.locator("#email").fill("hello@me.com");
  await page.locator("#password").fill("some password");

  const loginButton = page.locator("form button", { hasText: "Login" });

  await expect(loginButton).toHaveAttribute("type", "submit");

  await loginButton.click();

  await expect(page.locator(".notification-danger")).toHaveText(
    "User not found"
  );
});

test("Tries to login with valid credentials", async ({ page, context }) => {
  await page.goto("/login");

  await page.locator("#email").fill("user@email.com");
  await page.locator("#password").fill("some password");

  const loginButton = page.locator("form button", { hasText: "Login" });

  await expect(loginButton).toHaveAttribute("type", "submit");

  await loginButton.click();
  await page.waitForURL("/");
  expect(new URL(page.url()).pathname).toBe("/");
  const localStorage = (
    await context.storageState()
  ).origins[0].localStorage.reduce((acc: Record<string, string>, elem) => {
    acc[elem.name] = elem.value;
    return acc;
  }, {});
  expect(localStorage["auth-user-role"]).toBe("USER");
  expect(localStorage["auth-access-token"]).toBeDefined();
  expect(localStorage["auth-refresh-token"]).toBeDefined();
  expect(localStorage["auth-user-email"]).toBe("user@email.com");
  // Changes each run
  // expect(localStorage["auth-user-id"]).toBe("3");
  // Doesn't work in Chrome for some reason
  // expect(localStorage['auth-user-actor-id']).toBe('2');
});

test("Tries to login with valid credentials but unconfirmed account", async ({
  page,
}) => {
  await page.goto("/login");
  await page.locator("#email").fill("unconfirmed@email.com");
  await page.locator("#password").fill("some password");
  await page.keyboard.press("Enter");

  await expect(page.locator(".notification-danger")).toHaveText(
    "User not found"
  );
});

test("Tries to login with valid credentials, confirmed account but no profile", async ({
  page,
}) => {
  await page.goto("/login");
  await page.locator("#email").fill("confirmed@email.com");
  await page.locator("#password").fill("some password");
  await page.keyboard.press("Enter");

  await page.waitForURL("/register/profile/confirmed@email.com/true");
  expect(page.url()).toContain("/register/profile/confirmed@email.com/true");

  await expect(page.locator("p.prose").first()).toHaveText(
    "Now, create your first profile:"
  );

  const displayNameField = page.locator("form > .field").first();
  await expect(displayNameField.locator("label")).toHaveText(
    "Displayed nickname"
  );
  const displayNameInput = displayNameField.locator("input");
  await displayNameInput.fill("Duplicate");

  const usernameField = page.locator("form > .field").nth(1);
  await expect(usernameField.locator("label")).toHaveText("Username");
  const usernameFieldInput = usernameField.locator("input");
  await usernameFieldInput.fill("test_user");

  const descriptionField = page.locator("form > .field").nth(2);
  await expect(descriptionField.locator("label")).toHaveText("Short bio");
  await descriptionField
    .locator("textarea")
    .fill("This shouln't work because it's using a dupublicated username");

  const submitButton = page.locator('button[type="submit"]', {
    hasText: "Create my profile",
  });
  await submitButton.click();

  await expect(page.locator("p.field-message-danger")).toHaveText(
    "This username is already taken."
  );

  await displayNameInput.fill("");
  await displayNameInput.fill("Not");

  await usernameFieldInput.fill("");
  await usernameFieldInput.fill("test_user_2");

  await submitButton.click();

  // cy.get("form .field input").first(0).clear().type("test_user_2");
  // cy.get("form .field input").eq(1).type("Not");
  // cy.get("form .field textarea").clear().type("This will now work");
  // cy.get("form").submit();

  // cy.get(".navbar-link span.icon i").should(
  //   "have.class",
  //   "mdi-account-circle"
  // );

  await page.waitForURL("/");
  expect(page.url()).toContain("/");

  await expect(page.locator(".notification-info")).toHaveText(
    "Welcome to Mobilizon, Not!"
  );
  await expect(
    page.locator("button#user-menu-button span:not(.sr-only)")
  ).toHaveClass("material-design-icon account-circle-icon");
});
