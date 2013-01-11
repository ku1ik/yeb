Feature: Web application serving
  In order to work on my web app
  As a developer
  I want to be able to serve it by symlinking app directory

  Scenario: Request web app
    Given there's "dynamic" app symlinked as "foo"
    When I request http://foo.dev/
    Then I get status 200
    And I get text /dynamic app/
    And it touches spawner

  Scenario: Request web app, for the 2nd time
    Given there's "dynamic" app symlinked as "foo"
    When I request http://foo.dev/ for the 2nd time
    Then I get status 200
    And I get text /dynamic app/
    And it doesn't touch spawner

  Scenario: Restart web app
    Given there's running "dynamic" app symlinked as "foo"
    When I create restart.txt file in app's tmp dir
    And I request http://foo.dev/
    Then I get status 200
    And I get text /dynamic app/
    And I get newer app boot timestamp
    And it touches spawner
    When I request http://foo.dev/
    Then I get status 200
    And I get text /dynamic app/
    And I get the same app boot timestamp
    And it doesn't touch spawner
