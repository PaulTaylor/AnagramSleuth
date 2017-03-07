Feature: Looking for solutions to the countdown numbers game

  @javascript
  Scenario: I ask for a target of 123 with the numbers 1,2,3,4,5,6
    When I visit "/"
    And I enter "1,2,3,4,5,6" into "numbers"
    And I enter "123" into "target"
    And Submit the "numbers_group" form
    Then I should see "Result"
    #And I should see "(((4 × 5) × 6) + 3)"

  @javascript
  Scenario: I ask for a target of 727 with the numbers 50,100,9,1,9,3
    When I visit "/"
    And I enter "50,100,9,1,9,3" into "numbers"
    And I enter "727" into "target"
    And Submit the "numbers_group" form
    Then I should see "Result"
    And I should see "(((100 + 9) × 3) + ((9 - 1) × 50))"

  @javascript
  Scenario: There is an error on empty source numbers submission
    When I visit "/"
    And Submit the "numbers_group" form
    Then I should see "Source Numbers:"
    And I should see "You haven't entered any source numbers"

  @javascript
  Scenario: There is an error on empty target numbers submission
    When I visit "/"
    And I enter "1,2,3,4,5,6" into "numbers"
    And Submit the "numbers_group" form
    Then I should see "Target:"
    And I should see "You haven't entered a target number"
