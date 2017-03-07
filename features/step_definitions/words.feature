Feature: Looking for anagrams in text

  @javascript
  Scenario: I ask for anagrams of down
    When I visit "/"
    And I enter "down" into "Source String:"
    And Submit the "words_group" form
    Then I should see "We found 8 words within down."
    And I should see "dow"

  @javascript
  Scenario: There is an error on empty submission
    When I visit "/"
    And Submit the "words_group" form
    Then I should see "Source String:"
    And I should see "You haven't entered any words or letters"
