/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * (the "License"); you may not use this file except in compliance with the
 * License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * The Original Code is the StyleKit library.
 *
 * The Initial Developer of the Original Code is
 * Videojuicer Ltd. (UK Registered Company Number: 05816253).
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * 	Dan Glegg
 * 	Adam Livesley
 *
 * ***** END LICENSE BLOCK ***** */
package org.stylekit.spec.tests.ui.element.layout
{

	import flexunit.framework.Assert;
	import flexunit.framework.AsyncTestHelper;
	import org.flexunit.async.Async;

	import org.stylekit.css.value.SizeValue;
	import org.stylekit.css.value.DisplayValue;
	import org.stylekit.css.value.FloatValue;
	import org.stylekit.css.value.PositionValue;

	import org.stylekit.ui.element.UIElement;
	import org.stylekit.ui.element.layout.FlowControlLine;

	public class FlowControlLineTestCase {
		
		protected var _blockElem:UIElement;
		protected var _absElem:UIElement;
		protected var _floatLeftElems:Vector.<UIElement>;
		protected var _floatRightElems:Vector.<UIElement>;
		
		[Before]
		public function setUp():void
		{
			this._blockElem = new UIElement();
				this._blockElem.evaluatedStyles = {
					"width": SizeValue.parse("500px"),
					"height": SizeValue.parse("500px"),
					"display": DisplayValue.parse("block")
				};
				
			this._absElem = new UIElement();
				this._absElem.evaluatedStyles = {
					"width": SizeValue.parse("500px"),
					"height": SizeValue.parse("500px"),
					"position": PositionValue.parse("absolute")
				};
			
			this._floatLeftElems = new Vector.<UIElement>();
			this._floatRightElems = new Vector.<UIElement>();
			
			for(var i:uint=0; i<11; i++)
			{
				var fL:UIElement = new UIElement();
					fL.elementId = "floatLeft-"+i;
					fL.evaluatedStyles = {
						"float": FloatValue.parse("left"),
						"width": SizeValue.parse("51px"),
						"height": SizeValue.parse("5px")
					};

					this._floatLeftElems.push(fL);
					
				var fR:UIElement = new UIElement();
					fR.elementId = "floatRight-"+i;
					fR.evaluatedStyles = {
						"float": FloatValue.parse("right"),
						"width": SizeValue.parse("51px"),
						"height": SizeValue.parse("5px")
					};

					this._floatLeftElems.push(fR);
			}
		}
		
		[After]
		public function tearDown():void
		{
			this._blockElem = null;
			this._floatLeftElems = null;
			this._floatRightElems = null;
		}
		
		[Test(description="Ensures that a line may only be occupied by one block-level element at a time.")]
		public function linesAreBlockupied():void
		{
			var line:FlowControlLine = new FlowControlLine(1000, "left");
			var extraBlockElem:UIElement = new UIElement();
				extraBlockElem.evaluatedStyles = {
					"width": SizeValue.parse("500px"),
					"height": SizeValue.parse("500px"),
					"display": DisplayValue.parse("block")
				};
				
			Assert.assertTrue(line.treatElementAsNonFloatedBlock(this._blockElem));
			
			Assert.assertTrue(line.appendElement(this._blockElem));
			Assert.assertFalse(line.appendElement(this._blockElem));
			Assert.assertFalse(line.appendElement(extraBlockElem));
			
			line.removeElement(this._blockElem);
			Assert.assertTrue(line.appendElement(extraBlockElem));
		}
		
		[Test(description="Becomes full once the constrained width is reached from floated elements")]
		public function doesNotExceedMaxWidth():void
		{
			var line:FlowControlLine = new FlowControlLine(150, "left");
			Assert.assertTrue(line.appendElement(this._floatLeftElems[0]));
			Assert.assertTrue(line.appendElement(this._floatLeftElems[1]));
			Assert.assertFalse(line.appendElement(this._floatLeftElems[2])); // 3x51 > 150, so should be rejected
			
			line.removeElement(this._floatLeftElems[0]);
			Assert.assertTrue(line.appendElement(this._floatLeftElems[2]));
		}
		
		[Test(description="Ensures that the correct elements are refunded when prepending new elements")]
		public function elementsAreRefundedAfterPrependOperation():void
		{
			var line:FlowControlLine = new FlowControlLine(150, "left");
			Assert.assertTrue(line.appendElement(this._floatLeftElems[0]));
			Assert.assertTrue(line.appendElement(this._floatLeftElems[1]));
			
			var refunds:Vector.<UIElement> = line.prependElements(this._floatLeftElems.slice(2,3));
			Assert.assertEquals(1, refunds.length);
			Assert.assertEquals(this._floatLeftElems[1], refunds[0]);
			
			// assert element contents
			Assert.assertEquals(2, line.elements.length);
			Assert.assertEquals(this._floatLeftElems[2].elementId, line.elements[0].elementId);
			Assert.assertEquals(this._floatLeftElems[0].elementId, line.elements[1].elementId);
		}
		
		[Test(description="Ensures that the correct elements are refunded when changing the width")]
		public function elementsAreRefundedCorrectlyOnMaxWidthChanged():void
		{
			var line:FlowControlLine = new FlowControlLine(150, "left");
			Assert.assertEquals(51, this._floatLeftElems[1].effectiveWidth);
			Assert.assertTrue(line.appendElement(this._floatLeftElems[0]));
			Assert.assertTrue(line.appendElement(this._floatLeftElems[1]));
			
			var refunds:Vector.<UIElement>;
			
			// try shrinking
			refunds = line.setMaxWidth(100);
			Assert.assertEquals(1, line.elements.length);
			Assert.assertEquals(1, refunds.length);
			Assert.assertEquals(this._floatLeftElems[1], refunds[0]);
		}
		
		[Test(description="Ensures that lines are marked as occupied by absolute elements")]
		public function occupiedByAbsoluteElements():void
		{
			var line:FlowControlLine = new FlowControlLine(150, "left");
			Assert.assertTrue(line.treatElementAsAbsolute(this._absElem));
			Assert.assertFalse(line.treatElementAsAbsolute(this._blockElem));
			
			Assert.assertFalse(line.occupiedByAbsoluteElement);
			Assert.assertFalse(line.occupiedBySingleElement);
			
			Assert.assertTrue(line.appendElement(this._absElem));
			
			Assert.assertTrue(line.occupiedByAbsoluteElement);
			Assert.assertTrue(line.occupiedBySingleElement);;
			
			Assert.assertFalse(line.appendElement(this._blockElem));
		}
		
		[Test(description="Ensures that negative z-indexes are computed when added")]
		public function negativeZIndexesRespected():void
		{
			var line:FlowControlLine = new FlowControlLine(150, "left");
			var negElem:UIElement = new UIElement();
				negElem.localStyleString = "z-index: -200; float: left; width: 20px;";
			var posElem:UIElement = new UIElement();
				posElem.localStyleString = "z-index: 50; float: left; width: 20px;";
				
			Assert.assertEquals(0, line.highestZIndex);
			Assert.assertTrue(line.appendElement(negElem));
			Assert.assertEquals(-200, line.highestZIndex);
			Assert.assertTrue(line.appendElement(posElem));
			Assert.assertEquals(50, line.highestZIndex);
		}
	}
}