import { onBeforeLoad } from './browser-language';

beforeEach(() => {
  cy.restoreLocalStorage();
});

afterEach(() => {
  cy.saveLocalStorage();
});

describe('Login', () => {
  it('Tests that everything is present', () => {
    cy.visit('/login', { onBeforeLoad });

    cy.get('form .field').first().contains('label', 'Email');
    cy.get('form .field').last().contains('label', 'Password');
    cy.get('form').contains('button.button', 'Login');
    cy.get('form').contains('.control a.button', 'Forgot your password ?').click();
    cy.url().should('include', '/password-reset/send');
    cy.go('back');

    cy.get('form').contains('.control a.button', 'Register').click();
    cy.url().should('include', '/register/user');

    cy.go('back');
  });

  it('Tries to login with incorrect credentials', () => {
    cy.visit('/login', { onBeforeLoad });
    cy.get('input[type=email]').type('notanemail').should('have.value', 'notanemail');
    cy.get('input[type=password]').click();
    cy.contains('button.button.is-primary.is-large', 'Login').click();
    cy.get('form .field').first().contains('p.help.is-danger', 'Please include an \'@\' in the email address.');
    cy.get('form .field').last().contains('p.help.is-danger', 'Please fill out this field.');
  });

  it('Tries to login with invalid credentials', () => {
    cy.visit('/login', { onBeforeLoad });
    cy.get('input[type=email]').type('test@email.com').should('have.value', 'test@email.com');
    cy.get('input[type=password]').type('badPassword').should('have.value', 'badPassword');
    cy.contains('button.button.is-primary.is-large', 'Login').click();

    cy.contains('.message.is-danger', 'User with email not found');
  });
});
