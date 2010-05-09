//
//  BWStyledTextFieldCell.m
//  BWToolkit
//
//  Created by Brandon Walkin (www.brandonwalkin.com)
//  All code is provided under the New BSD license.
//

#import "BWStyledTextFieldCell.h"

@interface NSCell (BWPrivate)
- (NSDictionary *)_textAttributes;
@end

@interface BWStyledTextFieldCell (BWPrivate)
- (void)applyGradient;
@end

@interface BWStyledTextFieldCell ()
@property (retain) NSMutableDictionary *previousAttributes;
@property (nonatomic, retain) NSShadow *shadow;
@end

@implementation BWStyledTextFieldCell

@synthesize shadowIsBelow, shadowColor, hasShadow, shadow, previousAttributes, startingColor, endingColor, hasGradient, solidColor;

- (id)initWithCoder:(NSCoder *)decoder
{

	if ((self = [super initWithCoder:decoder]) != nil)
	{
		[self setShadowIsBelow:[decoder decodeBoolForKey:@"BWSTFCShadowIsBelow"]];
		[self setHasShadow:[decoder decodeBoolForKey:@"BWSTFCHasShadow"]];
		[self setHasGradient:[decoder decodeBoolForKey:@"BWSTFCHasGradient"]];
		[self setShadowColor:[decoder decodeObjectForKey:@"BWSTFCShadowColor"]];

		[self setPreviousAttributes:[decoder decodeObjectForKey:@"BWSTFCPreviousAttributes"]];
		[self setStartingColor:[decoder decodeObjectForKey:@"BWSTFCStartingColor"]];
		[self setEndingColor:[decoder decodeObjectForKey:@"BWSTFCEndingColor"]];
		[self setSolidColor:[decoder decodeObjectForKey:@"BWSTFCSolidColor"]];
		
		if (self.shadowColor == nil)
			self.shadowColor = [NSColor blackColor];
		
		if (self.startingColor == nil)
			self.startingColor = [NSColor whiteColor];
		
		if (self.endingColor == nil)
			self.endingColor = [NSColor blackColor];
		
		if (self.solidColor == nil)
			self.solidColor = [NSColor greenColor];
		
		if (self.hasGradient) {

			[self performSelector:@selector(applyGradient) withObject:nil afterDelay:0];
			
		} else {
		
			[self setTextColor:self.solidColor];
		
		}
			
		
			
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{

//	Else, the gradient (a pattern color) will get encoded and iPhone 3.2+’s Cocoa touch plug-in hates it.
	if ([self hasGradient]) [self setTextColor:[NSColor clearColor]];

	[super encodeWithCoder:coder];

	[coder encodeBool:[self shadowIsBelow] forKey:@"BWSTFCShadowIsBelow"];
	[coder encodeBool:[self hasShadow] forKey:@"BWSTFCHasShadow"];
	[coder encodeBool:[self hasGradient] forKey:@"BWSTFCHasGradient"];
	[coder encodeObject:[self shadowColor] forKey:@"BWSTFCShadowColor"];
	[coder encodeObject:[self previousAttributes] forKey:@"BWSTFCPreviousAttributes"];
	[coder encodeObject:[self startingColor] forKey:@"BWSTFCStartingColor"];
	[coder encodeObject:[self endingColor] forKey:@"BWSTFCEndingColor"];
	[coder encodeObject:[self solidColor] forKey:@"BWSTFCSolidColor"];
} 

- (id)copyWithZone:(NSZone *)zone
{
  BWStyledTextFieldCell *cell = (BWStyledTextFieldCell *)[super copyWithZone:zone];

  if (cell)
  {
    cell->previousAttributes = [previousAttributes mutableCopy];
    cell->shadow = [shadow retain];
    cell->shadowColor = [shadowColor retain];
    cell->startingColor = [startingColor retain];
    cell->endingColor = [endingColor retain];
    cell->solidColor = [solidColor retain];
  }

  return cell;
}

- (void)dealloc
{
	[shadow release];
	[previousAttributes release];
	[solidColor release];
	[endingColor release];
	[startingColor release];
	[shadowColor release];
	
	[super dealloc];
}

#pragma mark Text attributes

- (NSDictionary *) _textAttributes {

	NSMutableDictionary *attributes = [[[NSMutableDictionary alloc] init] autorelease];
	[attributes addEntriesFromDictionary:[super _textAttributes]];
	
//	Shadow
	if (hasShadow && [self shadow] != nil)
	[attributes setObject:[self shadow] forKey:NSShadowAttributeName];
	
//	Gradient
	if ([previousAttributes objectForKey:@"NSFont"] != nil && [[previousAttributes objectForKey:@"NSFont"] isEqualTo:[attributes objectForKey:@"NSFont"]] == NO) {

		[self performSelector:@selector(applyGradient) withObject:nil afterDelay:0];
		[self setPreviousAttributes:attributes];

	}
	
//	Cocoa touch IB Hack

	if ([self respondsToSelector:@selector(ibDidAddToDesignableDocument:)]) {
		
		NSString *key;
		
		BOOL couldShowGradient = NO;
		
		for (key in [NSThread callStackSymbols]) {
		
			if ([key rangeOfString:@"drawRect"].location != NSNotFound) {
			
				couldShowGradient = YES;
				break;
			
			}
		
		}
		
		if (!couldShowGradient)	
		[attributes setObject:self.solidColor forKey:@"NSColor"];

	}
	
	return attributes;
	
}

#pragma mark Shadow-specific code

- (void)changeShadow {

	NSShadow *tempShadow = [[[NSShadow alloc] init] autorelease];
	[tempShadow setShadowColor:shadowColor];
		
	if (shadowIsBelow)
		[tempShadow setShadowOffset:NSMakeSize(0,-1)];
	else
		[tempShadow setShadowOffset:NSMakeSize(0,1)];

	[self setShadow:tempShadow];
}

#pragma mark Gradient-specific code

- (void)awakeFromNib
{
	NSMutableDictionary *attributes = [[[NSMutableDictionary alloc] init] autorelease];
	[attributes addEntriesFromDictionary:[super _textAttributes]];
	self.previousAttributes = attributes;
	
	[self applyGradient];
}

- (void)applyGradient
{	
	if ([[self controlView] window] == nil)
		return;
	
	if (!self.hasGradient) return;
	
	[self setTextColor:[NSColor blackColor]];	// Giving bounds
	
	NSSize boundSizeWithFullWidth = NSMakeSize(
							   
		[self controlView].frame.size.width,
		[self controlView].frame.size.height
						   
	);
	
	NSImage *image = [[[NSImage alloc] initWithSize:boundSizeWithFullWidth] autorelease];

	NSLog(@"Making gradient out of colors %@ %@", self.startingColor, self.endingColor);
	
	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:self.startingColor endingColor:self.endingColor] autorelease];
	
	[image lockFocus];

	[gradient drawInRect: NSMakeRect (

		0,
		0,
		boundSizeWithFullWidth.width,
		boundSizeWithFullWidth.height
		
	) angle:270];
		
	[image unlockFocus];
	
	[self setTextColor:[NSColor colorWithPatternImage:image]];
	
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(
	
		0, 
		[[controlView superview] convertRect:[controlView frame] toView:nil].origin.y + 0
		
	)];	
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];

}

#pragma mark Accessors

- (void)setStartingColor:(NSColor *)color
{
	if (startingColor != color) 
	{
        [startingColor release];
        startingColor = [color retain];
		
		[self applyGradient];
    }
}

- (void)setEndingColor:(NSColor *)color
{	
	if (endingColor != color) 
	{
        [endingColor release];
        endingColor = [color retain];
		
		[self applyGradient];
    }
}

- (void)setSolidColor:(NSColor *)color {

	if (solidColor == color) return;

        [solidColor release];
        solidColor = [color retain];
		
	[self setTextColor:solidColor];
	
}





- (void)setHasGradient:(BOOL)flag {

	hasGradient = flag;
	
	if (flag) {
		
		[self applyGradient];
		
	} else {

		[self setTextColor:self.solidColor];
		
	}

}





- (void)setShadowIsBelow:(BOOL)flag {

	shadowIsBelow = flag;
	[self changeShadow];

}





- (void)setShadowColor:(NSColor *)color {

	if (shadowColor == color) return;

        [shadowColor release];
        shadowColor = [color retain];
		
	[self changeShadow];

}

@end
