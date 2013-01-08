Feature: Welcome page
  In order to start using Yeb
  As a developer
  I want to be presented with a welcome page including symlink example

  Scenario: Request non-app domain
    When I request http://localhost
    Then I get status 200
    And I get text /Welcome/
    And I get text /symlink/

  Scenario: Request via IP
    When I request http://127.0.0.1
    Then I get status 200
    And I get text /Welcome/
    And I get text /symlink/
