@temp-dir
Feature: Engine

  Background:

    Given a file "config/bootstrap-schema.xml":
      """
      <data>

        <schema name="schema">
          <id><text name="name"/></id>
          <fields/>
        </schema>

        <schema name="transform">
          <id><text name="name"/></id>
          <fields/>
        </schema>

        <transform name="bootstrap" rule="bootstrap">
          <output name="schema"/>
          <output name="transform"/>
        </transform>

      </data>
      """

    Given a file "config/rules/bootstrap.rb":
      """
      require "xml"

      proc do |hq|

        doc = XML::Document.string '
          <data>

            <schema name="input">
              <id><text name="name"/></id>
              <fields><text name="value"/></fields>
            </schema>

            <schema name="output">
              <id><text name="name"/></id>
              <fields><text name="value"/></fields>
            </schema>

            <schema name="schema">
              <id><text name="name"/></id>
              <fields/>
            </schema>

            <schema name="transform">
              <id><text name="name"/></id>
              <fields/>
            </schema>

            <transform name="bootstrap" rule="bootstrap">
              <output name="schema"/>
              <output name="transform"/>
            </transform>

            <transform name="input-to-output" rule="input-to-output">
              <input name="input"/>
              <output name="output"/>
              <match type="input"><field name="name" as="name"/></match>
            </transform>

          </data>
        '

        doc.root.each do |child|
          hq.write child
        end

      end
      """

    And a file "config/rules/input-to-output.rb":
      """
      require "xml"

      proc do |hq|

        input = hq.get "input", hq.input["name"]

        output = XML::Node.new "output"
        output["name"] = input["name"]
        output["value"] = input["value"].upcase
        hq.write output

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

# vim: et ts=2
