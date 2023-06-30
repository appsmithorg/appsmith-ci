import { ObjectsRegistry } from "../Objects/Registry";

const OnboardingLocator = require("../../locators/FirstTimeUserOnboarding.json");

let datasourceName;
export class Onboarding {
  private _aggregateHelper = ObjectsRegistry.AggregateHelper;
  private _datasources = ObjectsRegistry.DataSources;
  private _debuggerHelper = ObjectsRegistry.DebuggerHelper;

  completeSignposting() {
    cy.get(OnboardingLocator.checklistStatus).should("be.visible");
    cy.get(OnboardingLocator.checklistStatus).should("contain", "0 of 5");

    this._aggregateHelper
      .GetElement(OnboardingLocator.checklistConnectionBtn)
      .realHover()
      .should("have.css", "cursor", "not-allowed");
    cy.get(OnboardingLocator.checklistDatasourceBtn).click();
    cy.get(OnboardingLocator.datasourcePage).should("be.visible");
    this._aggregateHelper.AssertElementAbsence(OnboardingLocator.introModal);
    if (Cypress.env("AIRGAPPED")) {
      this._datasources.CreateDataSource("Mongo");
      cy.get("@dsName").then(($dsName) => {
        datasourceName = $dsName;
      });
    } else {
      cy.get(OnboardingLocator.datasourceMock).first().click();
    }
    cy.wait(1000);
    this._aggregateHelper.GetNClick(this._debuggerHelper.locators._helpButton);
    cy.get(OnboardingLocator.checklistStatus).should("contain", "1 of 5");
    this._aggregateHelper
      .GetElement(OnboardingLocator.checklistConnectionBtn)
      .realHover()
      .should("have.css", "cursor", "not-allowed");
    cy.get(OnboardingLocator.checklistActionBtn).should("be.visible");
    cy.get(OnboardingLocator.checklistActionBtn).click();
    cy.get(OnboardingLocator.createQuery).should("be.visible");
    cy.get(OnboardingLocator.createQuery).click();
    cy.wait(1000);
    this._aggregateHelper.GetNClick(this._debuggerHelper.locators._helpButton);
    cy.get(OnboardingLocator.checklistStatus).should("contain", "2 of 5");
    this._aggregateHelper
      .GetElement(OnboardingLocator.checklistActionBtn)
      .realHover()
      .should("have.css", "cursor", "auto");
    cy.get(OnboardingLocator.checklistWidgetBtn).should("be.visible");
    cy.get(OnboardingLocator.checklistWidgetBtn).click();
    cy.get(OnboardingLocator.widgetSidebar).should("be.visible");
    (cy as any).dragAndDropToCanvas("textwidget", { x: 400, y: 400 });
    this._aggregateHelper.GetNClick(this._debuggerHelper.locators._helpButton);
    cy.get(OnboardingLocator.checklistStatus).should("contain", "3 of 5");
    this._aggregateHelper
      .GetElement(OnboardingLocator.checklistWidgetBtn)
      .realHover()
      .should("have.css", "cursor", "auto");

    cy.get(OnboardingLocator.checklistConnectionBtn).should("be.visible");
    cy.get(OnboardingLocator.checklistConnectionBtn).click();
    cy.get(OnboardingLocator.snipingBanner).should("be.visible");
    cy.get(OnboardingLocator.snipingTextWidget)
      .first()
      .trigger("mouseover", { force: true })
      .wait(500);
    cy.get(OnboardingLocator.widgetName).should("be.visible");
    cy.get(OnboardingLocator.widgetName).click();
    this._aggregateHelper.GetNClick(this._debuggerHelper.locators._helpButton);
    cy.get(OnboardingLocator.checklistStatus).should("contain", "4 of 5");
    this._aggregateHelper
      .GetElement(OnboardingLocator.checklistConnectionBtn)
      .realHover()
      .should("have.css", "cursor", "auto");

    let open: any;
    cy.window().then((window: any) => {
      open = window.open;
      window.open = Cypress._.noop;
    });
    cy.get(OnboardingLocator.checklistDeployBtn).should("be.visible");
    cy.get(OnboardingLocator.checklistDeployBtn).click();
    this._aggregateHelper.AssertElementAbsence(OnboardingLocator.introModal);
    this._aggregateHelper.Sleep();

    this._aggregateHelper.GetNClick(this._debuggerHelper.locators._helpButton);
    this._aggregateHelper.AssertElementExist(
      OnboardingLocator.checklistCompletionBanner,
    );
    cy.window().then((window) => {
      window.open = open;
    });
  }

  closeIntroModal() {
    cy.get("body").then(($body) => {
      if ($body.find(OnboardingLocator.introModalCloseBtn).length) {
        this._aggregateHelper.GetNClick(OnboardingLocator.introModalCloseBtn);
      }
    });
  }
}