Feature: Standard test dataset
  Scenario: Invalid Json DataSet
    Given I have invalid JSON in standard test dataset
      |  Invalid Json |
    When I import JSON standard test dataset 
    Then I should get an error
      
