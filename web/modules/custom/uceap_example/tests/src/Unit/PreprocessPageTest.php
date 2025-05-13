<?php

namespace Drupal\Tests\uceap_example\Unit;

use Drupal\Tests\UnitTestCase;

/**
 * Unit test for uceap_example_preprocess_page().
 *
 * @group uceap_example
 */
class PreprocessPageTest extends UnitTestCase {

  /**
   * Tests the uceap_example_preprocess_page() function.
   */
  public function testPreprocessPage() {
    // Include the module file to load the function.
    require_once __DIR__ . '/../../../uceap_example.module';

    // Mock the variables array.
    $variables = [
      'page' => [
        'footer_bottom' => [],
      ],
    ];

    // Call the preprocess function.
    uceap_example_preprocess_page($variables);

    // Assert that the message was added to the footer_bottom region.
    $this->assertArrayHasKey('uceap_example_message', $variables['page']['footer_bottom']);
    $this->assertEquals(
      '<div id="hello-world">Hello, world!</div>',
      $variables['page']['footer_bottom']['uceap_example_message']['#markup']
    );
    $this->assertEquals(
      10,
      $variables['page']['footer_bottom']['uceap_example_message']['#weight']
    );
  }

}
