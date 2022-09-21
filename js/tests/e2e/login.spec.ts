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

  const registerLink = page.locator("a", { hasText: "Create an account" });

  await expect(forgotPasswordLink).toBeVisible();
  await expect(reAskInstructionsLink).toBeVisible();
  await expect(registerLink).toBeVisible();

  await expect(page.locator("form .field label").first()).toHaveText("Email");
  await expect(page.locator("form .field label").nth(1)).toHaveText("Password");

  await forgotPasswordLink.click();
  await page.waitForURL("/password-reset/send");
  await expect(page.url()).toContain("/password-reset/send");
  await page.goBack();

  await reAskInstructionsLink.click();
  await page.waitForURL("/resend-instructions");
  await expect(page.url()).toContain("/resend-instructions");
  await page.goBack();

  await registerLink.click();
  await page.waitForURL("/register/user");
  await expect(page.url()).toContain("/register/user");
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

  await page.locator("#email").fill("user@provider.org");
  await page.locator("#password").fill("valid_passw0rd");

  const loginButton = page.locator("form button", { hasText: "Login" });

  await expect(loginButton).toHaveAttribute("type", "submit");

  await loginButton.click();
  await page.waitForURL("/");
  await expect(new URL(page.url()).pathname).toBe("/");
  expect((await context.storageState()).origins[0].localStorage).toBe("toto");
});
