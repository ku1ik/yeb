Feature: Rack application serving
  In order to work on my Rack app
  As a developer
  I want to be able to serve it by symlinking app directory

  Scenario: Request rack app
    Given there's "rack" app symlinked as "foo"
    When I request http://foo.dev/
    Then I get status 200
    And I get text /rack app/
    And it touches spawner

  Scenario: Request rack app, for the 2nd time
    Given there's "rack" app symlinked as "foo"
    When I request http://foo.dev/ for the 2nd time
    Then I get status 200
    And I get text /rack app/
    And it doesn't touch spawner

  Scenario: Restart rack app
    Given there's running "rack" app symlinked as "foo"
    When I create restart.txt file in app's tmp dir
    And I request http://foo.dev/
    Then I get status 200
    And I get text /rack app/
    And I get newer app boot timestamp
    And it touches spawner
    When I request http://foo.dev/
    Then I get status 200
    And I get text /rack app/
    And I get the same app boot timestamp
    And it doesn't touch spawner
