import { onBeforeLoad } from './browser-language';

beforeEach(() => {
  cy.restoreLocalStorage();
  cy.checkoutSession();
});

afterEach(() => {
  cy.saveLocalStorage();
  cy.dropSession();
});

describe('Registration', () => {
  it('Tests that everything is present', () => {
    cy.visit('/register/user', { onBeforeLoad });

    cy.get('form .field').first().contains('label', 'Email');
    cy.get('form .field').eq(1).contains('label', 'Password');

    cy.get('input[type=email]').click();
    cy.get('input[type=password]').type('short').should('have.value', 'short');
    cy.get('form').contains('button.button.is-primary', 'Register');
    cy.get('form .field').first().contains('p.help.is-danger', 'Please fill out this field.');

    cy.get('form').contains('.control a.button', 'Didn\'t receive the instructions ?').click();
    cy.url().should('include', '/resend-instructions');
    cy.go('back');

    cy.get('form').contains('.control a.button', 'Login').click();
    cy.url().should('include', '/login');

    cy.go('back');
  });

  it('Tests that registration works', () => {
    cy.visit('/register/user', { onBeforeLoad });
    cy.get('input[type=email]').type('user@email.com');
    cy.get('input[type=password]').type('userPassword');
    cy.get('form').contains('button.button.is-primary', 'Register').click();

    cy.url().should('include', '/register/profile');
    cy.get('form .field').first().contains('label', 'Username').parent().find('input').type('tester');
    cy.get('form .field').eq(2).contains('label', 'Displayed name').parent().find('input').type('tester account');
    cy.get('form .field').eq(3).contains('label', 'Description').parent().find('textarea').type('This is a test account');
    cy.get('form .field').last().contains('button', 'Create my profile').click();

    cy.contains('article.message.is-success', 'Your account is nearly ready, tester').contains('A validation email was sent to user@email.com');

    cy.visit('/sent_emails');

    cy.get('iframe')
    .first()
    .iframeLoaded()
    .its('document')
    .getInDocument('a')
    .eq(1)
    .contains('Activate my account')
    .invoke('attr', 'href')
    .then(href => {
      cy.visit(href);
    });

    // cy.url().should('include', '/validate/');
    // cy.contains('Your account is being validated');
    cy.location().should((loc) => {
      expect(loc.pathname).to.eq('/');
    });
  });
});