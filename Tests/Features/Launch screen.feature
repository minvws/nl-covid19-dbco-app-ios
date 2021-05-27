Feature: Launch screen
	Scenario: Successful app launch
        Given the app launched
        Then I see a button with 'Volgende'
        When I tap the 'Volgende' button
        Then I see a button with 'Nee, geen code'
        When I tap the 'Nee, geen code' button
