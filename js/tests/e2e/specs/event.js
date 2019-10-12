import { onBeforeLoad } from './browser-language';

beforeEach(() => {
    cy.clearLocalStorage();
    cy.checkoutSession();
});

afterEach(() => {
    cy.dropSession();
});

describe('Events', () => {
    it('Shows my current events', () => {
        const EVENT = { title: 'My first event'};

        cy.loginUser();
        cy.visit('/events/me', { onBeforeLoad });
        cy.contains('.message.is-danger', 'No events found');
        cy.contains('.navbar-item', 'Create').click();

        cy.url().should('include', 'create');
        cy.get('.field').first().find('input').type(EVENT.title);
        cy.get('.field').eq(1).find('input').type('my tag, holo{enter}');
        cy.get('.field').eq(2).find('.datepicker .dropdown-trigger').click();

        cy.get('.field').eq(3).find('.pagination-list .control').first().find('.select select').select('September');
        cy.get('.field').eq(3).find('.pagination-list .control').last().find('.select select').select('2021');
        cy.wait(1000);
        cy.get('.field').eq(3).contains('.datepicker-cell', '15').click();

        cy.contains('.button.is-primary', 'Create my event').click();
        cy.url().should('include', '/events/');
        cy.contains('.title', EVENT.title);
        cy.contains('.title-and-informations span small', 'You\'re the only one going to this event');
        cy.contains('.date-and-privacy', 'On Wednesday, September 15, 2021 from');
        cy.contains('.visibility .tag', 'Public event');

        cy.contains('.navbar-item', 'My events').click();
        cy.contains('.title', EVENT.title);
        cy.contains('.content.column', 'You\'re organizing this event');
        cy.contains('.title-wrapper .date-component .datetime-container .month', 'Sep');
        cy.contains('.title-wrapper .date-component .datetime-container .day', '15');
    });
});