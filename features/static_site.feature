Feature: Static site
  In order to work on my static site
  As a developer
  I want to be able to serve it by symlinking site directory

  # First requests, handled by spawner

  Scenario: Request static page root
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/
    Then I get status 200
    And I get text /static site/
    And it touches spawner

  Scenario: Request static page other than index
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/other.html
    Then I get status 200
    And I get text /other static site/
    And it touches spawner

  Scenario: Request static page other than index, without .html extension
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/other
    Then I get status 200
    And I get text /other static site/
    And it touches spawner

  Scenario: Request static page other than index, as a directory
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/dir/
    Then I get status 200
    And I get text /in a dir/
    And it touches spawner

  Scenario: Request non-existent page
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/not-here
    Then I get status 404
    And I get text /[Nn]ot [Ff]ound/
    And it touches spawner

  # Second requests, handled by nginx only

  Scenario: Request static page root, for the 2nd time
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/ for the 2nd time
    Then I get status 200
    And I get text /static site/
    And it doesn't touch spawner

  Scenario: Request static page other than index, for the 2nd time
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/other.html for the 2nd time
    Then I get status 200
    And I get text /other static site/
    And it doesn't touch spawner

  Scenario: Request static page other than index, without .html extension, for the 2nd time
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/other for the 2nd time
    Then I get status 200
    And I get text /other static site/
    And it doesn't touch spawner

  Scenario: Request static page other than index, as a directory, for the 2nd time
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/dir/ for the 2nd time
    Then I get status 200
    And I get text /in a dir/
    And it doesn't touch spawner

  Scenario: Request non-existent page, for the 2nd time
    Given there's "static" app symlinked as "foo"
    When I request http://foo.dev/not-here for the 2nd time
    Then I get status 404
    And I get text /[Nn]ot [Ff]ound/
    And it doesn't touch spawner

  # Unlinking

  Scenario: Request page after removing symlink
    Given there's running "static" app symlinked as "foo"
    When I remove symlink "foo"
    And I request http://foo.dev/
    Then I get status 404
    And I get text /ln -s/
