Feature: Launch screen
	Scenario: Successful app launch
        Given the app launched
        Then I see a button with 'Volgende'
        When I tap the 'Volgende' button
        Then I see a button with 'Ja, ik heb een code'
        And I see a button with 'Nee, geen code'
        When I tap the 'Nee, geen code' button
        Then I see a label with 'Wat zijn de eerste vier cijfers van je postcode?'
        And I see a text field with '0000'
        And I see a disabled button with 'Volgende'
        When I type '8888' into the '0000' text field
        Then the 'Volgende' button becomes enabled
        When I tap the 'Volgende' button
        Then I see a button with 'Ik snap het' or 'Volgende'
        When I tap the 'Ik snap het' or 'Volgende' button
        Then I see a label with 'Zo gaat GGD Contact om met je gegevens'
        And I see a switch with 'Ik heb de privacyverklaring gelezen en begrijp hoe GGD Contact mijn gegevens gebruikt'
        And I see a disabled button with 'Volgende'
        When I tap the 'Ik heb de privacyverklaring gelezen en begrijp hoe GGD Contact mijn gegevens gebruikt' switch
        Then the 'Volgende' button becomes enabled
        When I tap the 'Volgende' button
        Then I see a label with 'Welke klachten heb je die bij COVID-19 passen?'
        # When I swipe up
        # Then I see a button with 'Ik heb geen klachten'
        # When I swipe down
        And I tap the 'Keelpijn' switch
        And I tap the 'Neusverkoudheid' switch
        And I swipe up
        Then I see a button with 'Volgende'
        When I tap the 'Volgende' button
        Then I see a label with 'Sinds wanneer heb je deze klachten?'
        And I see a button with 'Volgende'
        When I tap the 'Volgende' button
        Then I see a label starting with 'Weet je zeker dat je geen klachten had op'
        And I see a button with 'Geen klachten'
        When I tap the 'Geen klachten' button
        Then I see a label with 'Wil je je contactenlijst gebruiken om contactgegevens in te vullen?'
        And I see a button with 'Toegang geven'
        When I tap the 'Toegang geven' button
        And I allow access to contacts
        Then I see a text field with 'Voeg huisgenoot toe'
        And I see a button with 'Ik woon alleen'
        When I type 'Anna Haro' into the 'Voeg huisgenoot toe' text field
        And I type 'Daniel Higgins' into the 'Voeg huisgenoot toe' text field
        And I swipe up
        Then I see a button with 'Volgende'
