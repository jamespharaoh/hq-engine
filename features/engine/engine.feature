@temp-dir
Feature: Engine

  Background:

    Given a file "config/rules/input-schema.rb":
      """
      # (: out schema :)
      require "xml"
      proc do |hq|
        doc = XML::Document.string '
          <schema name="input">
            <id><text name="name"/></id>
            <fields><text name="value"/></fields>
          </schema>
        '
        hq.write doc.root
      end
      """

    And a file "config/rules/schema-schema.rb":
      """
      # (: out schema :)
      require "xml"
      proc do |hq|
        doc = XML::Document.string '
          <schema name="schema">
            <id><text name="name"/></id>
            <fields/>
          </schema>
        '
        hq.write doc.root
      end
      """

    And a file "config/rules/output-schema.rb":
      """
      # (: out schema :)
      require "xml"
      proc do |hq|
        doc = XML::Document.string '
          <schema name="output">
            <id><text name="name"/></id>
            <fields><text name="value"/></fields>
          </schema>
        '
        hq.write doc.root
      end
      """

    And a file "config/rules/input-to-output.rb":
      """
      # (: in input :)
      # (: out output :)
      require "xml"
      proc do |hq|
        hq.find("input").each do
          |input|
          output = XML::Node.new "output"
          output["name"] = input["name"]
          output["value"] = input["value"].upcase
          hq.write output
        end
      end
      """

    And a file "work/input.yaml":
      """
      - id: input/name
        type: input
        value:
          name: name
          value: value
      """

    And a file "default.args":
      """
      --config config
      --work work
      """

  Scenario: Success

    When I invoke engine with "default.args"

    Then there should be a file "work/output/data/output/name.xml":
      """
      <output name="name" value="VALUE"/>
      """

    Then there should be a file "work/output/data/schema/schema.xml":
      """
      <schema name="schema">
        <id>
          <text name="name"/>
        </id>
        <fields/>
      </schema>
      """

    Then there should be a file "work/output/data/schema/output.xml":
      """
      <schema name="output">
        <id>
          <text name="name"/>
        </id>
        <fields>
          <text name="value"/>
        </fields>
      </schema>
      """

    Then there should be a file "work/output/data/schema/input.xml":
      """
      <schema name="input">
        <id>
          <text name="name"/>
        </id>
        <fields>
          <text name="value"/>
        </fields>
      </schema>
      """

    Then there should be a file "work/output/data/input/name.xml":
      """
      <input name="name" value="value"/>
      """

