Feature: Visiting the home page

  Scenario: I visit the homepage.
    When I visit "/"
    Then I should see "Welcome to Anagram Sleuth"
     And I should not see "Error"
