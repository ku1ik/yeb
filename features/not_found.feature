Feature: 404 page
  In order to enable my app
  As a developer
  I want to be presented with a symlink command example

  Scenario: Request non-symlinked app
    Given there's no app foo
    When I request http://foo.dev
    Then I get status 404
    And I get text /Application "foo" not found/
    And I get text /ln -s/
